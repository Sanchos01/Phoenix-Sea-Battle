defmodule PhoenixSeaBattle.Game do
  use GenServer
  require Logger
  alias PhoenixSeaBattle.Game.Board
  alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.{Endpoint, Presence}
  alias PhoenixSeaBattle.User
  @reconnect_time Application.get_env(:phoenix_sea_battle, :reconnect_time, 30)
  @timeout 1_000
  @get_keys ~w(admin opponent turn playing winner)a

  defstruct [
    id: nil,
    admin: nil,
    admin_pid: nil,
    admin_board: nil,
    admin_shots: [],
    opponent: nil,
    opponent_pid: nil,
    opponent_board: nil,
    opponent_shots: [],
    turn: nil,
    playing: false,
    winner: nil,
    timer: nil,
    offline: [],
    messages: []
  ]

  def start_link(name, opts) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init([id: id]) do
    :ok = Endpoint.subscribe("game:" <> id)
    :timer.send_interval(@timeout, :timeout)
    case :ets.lookup(:saver, id) do
      [{_id, state, _ttl}] -> {:ok, state}
      _ -> {:ok, %__MODULE__{id: id}}
    end
  end
  def init(_), do: {:stop, "No id"}

  def get(pid, user \\ nil),            do: GenServer.call(pid, {:get, user})
  def get_messages(pid),                do: GenServer.call(pid, :get_messages)
  def get_board_and_shots(pid, user),   do: GenServer.call(pid, {:get_board_and_shots, user})
  def add_user(pid, user),              do: GenServer.call(pid, {:add_user, user})
  def apply_ship(pid, user, ship_opts), do: GenServer.cast(pid, {:apply_ship, user, ship_opts})
  def new_msg(pid, msg),                do: GenServer.cast(pid, {:new_msg, msg})

  # Calls
  # get
  def handle_call({:get, nil}, _from, state), do: {:reply, {:ok, state}, state}
  def handle_call({:get, %User{id: id}}, {pid, _ref}, state) do
    new_state = case state do
      %{admin: %User{id: ^id}, admin_pid: old_pid} when old_pid != pid ->
        %{state | admin_pid: pid}
      %{opponent: %User{id: ^id}, admin_pid: old_pid} when old_pid != pid ->
        %{state | opponent_pid: pid}
      _ ->
        state
    end
    reply =
      new_state
      |> Map.update(:admin, nil, fn nil -> nil; %User{name: name} -> name end)
      |> Map.update(:opponent, nil, fn nil -> nil; %User{name: name} -> name end)
      |> Map.take(@get_keys)
    {:reply, {:ok, reply}, new_state}
  end

  def handle_call(:get_messages, _from, state = %{messages: messages}) do
    {:reply, messages, state}
  end

  def handle_call({:get_board_and_shots, user}, _from, state = %{admin: user}) do
    {:reply, {:ok, state.admin_board, state.admin_shots, state.opponent_shots}, state}
  end

  def handle_call({:get_board_and_shots, user}, _from, state = %{opponent: user}) do
    {:reply, {:ok, state.opponent_board, state.opponent_shots, state.admin_shots}, state}
  end

  def handle_call({:get_board_and_shots, _}, _from, state) do
    {:reply, :error, state}
  end

  # add_user
  def handle_call({:add_user, user}, _from, state = %{admin: nil}) do
    {:reply, {:ok, :admin}, %{state | admin: user, admin_board: Board.new_board()}}
  end
  def handle_call({:add_user, %User{} = user}, _from, state = %{admin: admin, opponent: nil}) do
    if user.id != admin.id do
      {:reply, {:ok, :opponent}, %{state | opponent: user, opponent_board: Board.new_board()}}
    else
      {:reply, {:ok, :admin}, state}
    end
  end
  def handle_call({:add_user, %User{} = user}, _from, state = %{admin: admin, opponent: opponent}) do
    cond do
      user.id == admin.id    -> {:reply, {:ok, :admin}, state}
      user.id == opponent.id -> {:reply, {:ok, :opponent}, state}
      true                   -> {:reply, {:error, "game already full"}, state}
    end
  end

  # Casts
  def handle_cast({:new_msg, %{user: user, body: body}}, state) do
    msg = %{user: user, body: body, ts: :os.system_time(:second)}
    messages = [msg | Enum.take(state.messages, 20)]
    if p = state.admin_pid, do: send p, {:update_messages, messages}
    if p = state.opponent_pid, do: send p, {:update_messages, messages}
    {:noreply, %{state | messages: messages}}
  end

  def handle_cast({:apply_ship, user_id, ship_opts}, state = %{admin: %{id: user_id}}) do
    board = state.admin_board
    case Board.apply_ship(board, ship_opts) do
      {:ok, new_board} ->
        send state.admin_pid, :update_state
        {:noreply, %{state | admin_board: new_board}}
      {:error, error} ->
        send state.admin_pid, {:render_error, error}
        {:noreply, state}
    end
  end

  # Infos
  def handle_info(%Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, state = %{offline: offline, timer: timer}) do
    Logger.debug "#{state.id} --- checking diffs - joins: #{inspect joins}, leaves: #{inspect leaves}"

    leaves_users = Map.keys(leaves)
    {offline, timer} = if length(leaves_users) > 0 do
      {Enum.uniq(offline ++ leaves_users), (timer || (System.system_time(:second) + @reconnect_time))}
    else
      {offline, timer}
    end

    join_users = Map.keys(joins)
    {offline, timer} = if length(join_users) > 0 do
      case offline -- join_users do
        []      -> {[], nil}
        offline -> {offline, timer}
      end
    else
      {offline, timer}
    end

    {:noreply, %{state | timer: timer, offline: offline}}
  end

  def handle_info(msg = %Broadcast{}, state) do
    Logger.info("nothing intresting, msg - #{inspect msg}")
    {:noreply, state}
  end

  def handle_info(:timeout, state = %{timer: nil}), do: {:noreply, state}
  def handle_info(:timeout, state = %{timer: timer, offline: []}) when timer != nil do
    Logger.error("timer on, but offline no one")
    case compare_state_and_presence(state) do
      [] -> {:noreply, %{state | timer: nil}}
      offline -> {:noreply, %{state | offline: offline}}
    end
  end
  def handle_info(:timeout, state = %{timer: timer}) do
    cond do
      compare_state_and_presence(state) == [] ->
        {:noreply, %{state | timer: nil}}

      System.system_time(:second) > timer ->
        Logger.warn("game #{state.id} stopped (cause no one)")
        {:stop, :normal, state}

      true ->
        {:noreply, state}
    end
  end

  def handle_info({:terminate, %User{} = user}, state = %{admin: admin, opponent: opponent}) do
    cond do
      user.id == admin.id ->
        # if opponent, do: cast_change_user_states(%{opponent.name => %{state: 3}})
        {:stop, :normal, state} # TODO don't stop game few seconds
      user.id == opponent.id ->
        # cast_change_user_states(%{admin.name => %{state: 1, game_id: state.id}})
        {:noreply, %{state | opponent: nil}}
      true ->
        Logger.warn "who send terminate?: #{inspect user}"
        {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    Logger.warn("uncatched message: #{inspect msg}")
    {:noreply, state}
  end

  def terminate(:normal, %{id: id}) do
    Endpoint.broadcast("game:" <> id, "all out", %{})
    :ok
  end

  def terminate(reason, state) do
    Logger.error("Unusual stop game #{state.id} with reason #{inspect reason}, state: #{inspect state}")
    :ets.insert :saver, {state.id, state, :os.system_time(:second)}
    :ok
  end

  # defp cast_change_user_states(meta), do: Endpoint.broadcast("room:lobby", "change_state", %{"users" => meta})

  defp compare_state_and_presence(state = %{id: id}) do
    state_users =
      [state.admin, state.opponent]
      |> Stream.map(&get_user_name/1)
      |> Enum.reject(&is_nil/1)

    presence =
      "game:#{id}"
      |> Presence.list()
      |> Map.keys()

    state_users -- presence
  end

  defp get_user_name(%User{name: name}), do: name
  defp get_user_name(_), do: nil
end
