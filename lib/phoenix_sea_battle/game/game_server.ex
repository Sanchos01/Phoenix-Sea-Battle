defmodule PhoenixSeaBattle.GameServer do
  use GenServer
  require Logger
  alias PhoenixSeaBattle.Game.Board
  alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.{Endpoint, Presence}
  alias PhoenixSeaBattle.User
  @reconnect_time Application.get_env(:phoenix_sea_battle, :reconnect_time, 30)
  @timeout 1_000
  @get_keys ~w(admin opponent turn playing winner)a
  @enforce_keys ~w(id)a

  defstruct id: nil,
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

  def start_link(name, opts) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(id: id) do
    :ok = Endpoint.subscribe("game:" <> id)
    :timer.send_interval(@timeout, :timeout)

    case :ets.lookup(:saver, id) do
      [{_id, state, _ttl}] -> {:ok, state}
      _ -> {:ok, %__MODULE__{id: id}}
    end
  end

  def get(pid, user \\ nil),            do: GenServer.call(pid, {:get, user})
  def get_messages(pid),                do: GenServer.call(pid, :get_messages)
  def get_board_and_shots(pid, user),   do: GenServer.call(pid, {:get_board_and_shots, user})
  def add_user(pid, user),              do: GenServer.call(pid, {:add_user, user})
  def apply_ship(pid, user, ship_opts), do: GenServer.cast(pid, {:apply_ship, user, ship_opts})
  def new_msg(pid, msg),                do: GenServer.cast(pid, {:new_msg, msg})
  def drop_last(pid, user_id),          do: GenServer.cast(pid, {:drop_last, user_id})
  def drop_all(pid, user_id),           do: GenServer.cast(pid, {:drop_all, user_id})
  def ready(pid, user_id),              do: GenServer.cast(pid, {:ready, user_id})
  def unready(pid, user_id),            do: GenServer.cast(pid, {:unready, user_id})
  def shot(pid, user_id, index),        do: GenServer.cast(pid, {:shot, user_id, index})

  # Calls
  # get
  def handle_call({:get, %User{id: id}}, {pid, _ref}, state = %{admin: %User{id: id}}) do
    new_state = if state.admin_pid != pid, do: %__MODULE__{state | admin_pid: pid}, else: state
    {:reply, make_get_reply(new_state), new_state}
  end

  def handle_call({:get, %User{id: id}}, {pid, _ref}, state = %{opponent: %User{id: id}}) do
    new_state =
      if state.opponent_pid != pid, do: %__MODULE__{state | opponent_pid: pid}, else: state

    {:reply, make_get_reply(new_state), new_state}
  end

  def handle_call({:get, _}, _from, state) do
    {:reply, :error, state}
  end

  def handle_call(:get_messages, _from, state = %__MODULE__{messages: messages}) do
    {:reply, messages, state}
  end

  def handle_call(
        {:get_board_and_shots, %User{id: id}},
        _from,
        state = %__MODULE__{admin: %{id: id}}
      ) do
    {:reply, {:ok, state.admin_board, state.admin_shots, state.opponent_shots}, state}
  end

  def handle_call(
        {:get_board_and_shots, %User{id: id}},
        _from,
        state = %__MODULE__{opponent: %{id: id}}
      ) do
    {:reply, {:ok, state.opponent_board, state.opponent_shots, state.admin_shots}, state}
  end

  def handle_call({:get_board_and_shots, _}, _from, state) do
    {:reply, :error, state}
  end

  # add_user
  def handle_call({:add_user, %User{} = user}, _from, state = %__MODULE__{admin: nil}) do
    {:reply, {:ok, :admin}, %__MODULE__{state | admin: user, admin_board: Board.new_board()}}
  end

  def handle_call(
        {:add_user, %User{} = user},
        _from,
        state = %__MODULE__{admin: admin, opponent: nil}
      ) do
    if user.id != admin.id do
      state.admin_pid && send(state.admin_pid, :update_state)
      new_state = %__MODULE__{state | opponent: user, opponent_board: Board.new_board()}
      {:reply, {:ok, :opponent}, new_state}
    else
      {:reply, {:ok, :admin}, state}
    end
  end

  def handle_call(
        {:add_user, %User{} = user},
        _from,
        state = %__MODULE__{admin: admin, opponent: opponent}
      ) do
    cond do
      user.id == admin.id -> {:reply, {:ok, :admin}, state}
      user.id == opponent.id -> {:reply, {:ok, :opponent}, state}
      true -> {:reply, {:error, "game already full"}, state}
    end
  end

  # Casts
  def handle_cast({:new_msg, %{user: user, body: body}}, state) do
    msg = %{user: user, body: body, ts: :os.system_time(:second)}
    messages = [msg | Enum.take(state.messages, 20)]
    state.admin_pid && send(state.admin_pid, {:update_messages, messages})
    state.opponent_pid && send(state.opponent_pid, {:update_messages, messages})
    {:noreply, %__MODULE__{state | messages: messages}}
  end

  def handle_cast({:apply_ship, user_id, ship_opts}, state = %__MODULE__{admin: %{id: user_id}}) do
    board = state.admin_board

    case Board.apply_ship(board, ship_opts) do
      {:ok, new_board} ->
        send_update_stats([state.admin_pid])
        {:noreply, %__MODULE__{state | admin_board: new_board}}

      {:error, error} ->
        send(state.admin_pid, {:render_error, error})
        {:noreply, state}
    end
  end

  def handle_cast(
        {:apply_ship, user_id, ship_opts},
        state = %__MODULE__{opponent: %{id: user_id}}
      ) do
    board = state.opponent_board

    case Board.apply_ship(board, ship_opts) do
      {:ok, new_board} ->
        send_update_stats([state.opponent_pid])
        {:noreply, %__MODULE__{state | opponent_board: new_board}}

      {:error, error} ->
        send(state.opponent_pid, {:render_error, error})
        {:noreply, state}
    end
  end

  def handle_cast(
        {:drop_last, user_id},
        state = %__MODULE__{admin: %{id: user_id}, playing: false, winner: nil}
      ) do
    dropping_last(:admin, state)
  end

  def handle_cast(
        {:drop_last, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: false, winner: nil}
      ) do
    dropping_last(:opponent, state)
  end

  def handle_cast(
        {:drop_last, user_id},
        state = %__MODULE__{admin: %{id: user_id}, playing: {:ready, user_id2}}
      )
      when user_id != user_id2 do
    dropping_last(:admin, state)
  end

  def handle_cast(
        {:drop_last, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: {:ready, user_id2}}
      )
      when user_id != user_id2 do
    dropping_last(:opponent, state)
  end

  def handle_cast({:drop_last, _}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {:drop_all, user_id},
        state = %{admin: %{id: user_id}, playing: false, winner: nil}
      ) do
    dropping_all(:admin, state)
  end

  def handle_cast(
        {:drop_all, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: false, winner: nil}
      ) do
    dropping_all(:opponent, state)
  end

  def handle_cast(
        {:drop_all, user_id},
        state = %__MODULE__{admin: %{id: user_id}, playing: {:ready, user_id2}}
      )
      when user_id != user_id2 do
    dropping_all(:admin, state)
  end

  def handle_cast(
        {:drop_all, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: {:ready, user_id2}}
      )
      when user_id != user_id2 do
    dropping_all(:opponent, state)
  end

  def handle_cast({:drop_all, _}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {:ready, user_id},
        state = %__MODULE__{admin: %{id: user_id}, playing: false, winner: nil}
      ) do
    if Board.prepare(state.admin_board) == :ok do
      send_update_stats([state.admin_pid, state.opponent_pid])
      {:noreply, %__MODULE__{state | playing: {:ready, user_id}}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(
        {:ready, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: false, winner: nil}
      ) do
    if Board.prepare(state.opponent_board) == :ok do
      send_update_stats([state.admin_pid, state.opponent_pid])
      {:noreply, %__MODULE__{state | playing: {:ready, user_id}}}
    else
      {:noreply, state}
    end
  end

  def handle_cast(
        {:ready, user_id},
        state = %__MODULE__{admin: %{id: user_id}, playing: {:ready, user_id2}}
      ) do
    if user_id != user_id2 and Board.prepare(state.admin_board) == :ok do
      send_update_stats([state.admin_pid, state.opponent_pid])
      turn = Enum.random([state.admin.id, state.opponent.id])

      {:noreply,
       %__MODULE__{
         state
         | playing: true,
           turn: turn,
           admin_shots: state.opponent_board,
           opponent_shots: state.admin_board
       }}
    else
      {:noreply, state}
    end
  end

  def handle_cast(
        {:ready, user_id},
        state = %__MODULE__{opponent: %{id: user_id}, playing: {:ready, user_id2}}
      ) do
    if user_id != user_id2 and Board.prepare(state.opponent_board) == :ok do
      send_update_stats([state.admin_pid, state.opponent_pid])
      turn = Enum.random([state.admin.id, state.opponent.id])

      {:noreply,
       %__MODULE__{
         state
         | playing: true,
           turn: turn,
           admin_shots: state.opponent_board,
           opponent_shots: state.admin_board
       }}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:ready, _user_id}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {:unready, user_id},
        state = %__MODULE__{playing: {:ready, user_id}, winner: nil}
      ) do
    send_update_stats([state.admin_pid, state.opponent_pid])
    {:noreply, %__MODULE__{state | playing: false}}
  end

  def handle_cast({:unready, _user_id}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {:shot, user_id, index},
        state = %__MODULE__{playing: true, turn: user_id, admin: %{id: user_id}}
      ) do
    {:ok, new_shots, same_turn?} =
      Board.apply_shot(state.opponent_board, state.admin_shots, index)

    send_update_stats([state.admin_pid, state.opponent_pid])

    if Board.all_dead?(new_shots) do
      {:noreply, %__MODULE__{state | admin_shots: new_shots, winner: user_id, playing: false}}
    else
      new_turn = if same_turn?, do: state.turn, else: state.opponent.id
      {:noreply, %__MODULE__{state | admin_shots: new_shots, turn: new_turn}}
    end
  end

  def handle_cast(
        {:shot, user_id, index},
        state = %__MODULE__{playing: true, turn: user_id, opponent: %{id: user_id}}
      ) do
    {:ok, new_shots, same_turn?} =
      Board.apply_shot(state.admin_board, state.opponent_shots, index)

    send_update_stats([state.admin_pid, state.opponent_pid])

    if Board.all_dead?(new_shots) do
      {:noreply, %__MODULE__{state | opponent_shots: new_shots, winner: user_id, playing: false}}
    else
      new_turn = if same_turn?, do: state.turn, else: state.admin.id
      {:noreply, %__MODULE__{state | opponent_shots: new_shots, turn: new_turn}}
    end
  end

  def handle_cast({:shot, _user_id, _index}, state) do
    {:noreply, state}
  end

  # Infos
  def handle_info(
        %Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        state = %__MODULE__{offline: offline, timer: timer}
      ) do
    Logger.debug(
      "#{state.id} --- checking diffs - joins: #{inspect(joins)}, leaves: #{inspect(leaves)}"
    )

    leaves_users = Map.keys(leaves)

    {offline, timer} =
      if length(leaves_users) > 0 do
        {Enum.uniq(offline ++ leaves_users),
         timer || System.system_time(:second) + @reconnect_time}
      else
        {offline, timer}
      end

    join_users = Map.keys(joins)

    {offline, timer} =
      if length(join_users) > 0 do
        case offline -- join_users do
          [] -> {[], nil}
          offline -> {offline, timer}
        end
      else
        {offline, timer}
      end

    {:noreply, %__MODULE__{state | timer: timer, offline: offline}}
  end

  def handle_info(%Broadcast{}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, state = %__MODULE__{timer: nil}), do: {:noreply, state}

  def handle_info(:timeout, state = %__MODULE__{timer: timer, offline: []}) when timer != nil do
    Logger.error("timer on, but offline no one")

    case compare_state_and_presence(state) do
      [] -> {:noreply, %__MODULE__{state | timer: nil}}
      offline -> {:noreply, %__MODULE__{state | offline: offline}}
    end
  end

  def handle_info(:timeout, state = %__MODULE__{timer: timer}) do
    cond do
      compare_state_and_presence(state) == [] ->
        {:noreply, %__MODULE__{state | timer: nil}}

      System.system_time(:second) > timer ->
        Logger.warn("game #{state.id} stopped (cause no one)")
        {:stop, :normal, state}

      true ->
        {:noreply, state}
    end
  end

  def handle_info({:terminate, %User{id: id}}, state = %__MODULE__{admin: %User{id: id}}) do
    # if opponent, do: cast_change_user_states(%{opponent.name => %__MODULE__{state: 3}}) # old functions, needs rework
    # TODO don't stop game few seconds, annonce to opponent about ending?
    state.opponent_pid && send(state.opponent_pid, :exit)
    {:stop, :normal, state}
  end

  def handle_info({:terminate, %User{id: id}}, state = %__MODULE__{opponent: %User{id: id}}) do
    # cast_change_user_states(%{admin.name => %__MODULE__{state: 1, game_id: state.id}}) # old functions, needs rework
    # TODO maybe win, depends on playing and winner
    state.admin_pid && send(state.admin_pid, :update_state)

    new_state = %__MODULE__{
      state
      | opponent: nil,
        opponent_pid: nil,
        opponent_board: nil,
        opponent_shots: []
    }

    {:noreply, new_state}
  end

  def terminate(:normal, state = %__MODULE__{id: _id}) do
    state.admin_pid && send(state.admin_pid, :retry_connect)
    state.opponent_pid && send(state.opponent_pid, :retry_connect)
    :ok
  end

  def terminate(_reason, state) do
    state.admin_pid && send(state.admin_pid, :retry_connect)
    state.opponent_pid && send(state.opponent_pid, :retry_connect)
    :ets.insert(:saver, {state.id, state, :os.system_time(:second) + 30_000})
    :ok
  end

  defp make_get_reply(state) do
    state
    |> Map.update(:admin, nil, &get_user_name/1)
    |> Map.update(:opponent, nil, &get_user_name/1)
    |> Map.take(@get_keys)
    |> then(fn x -> {:ok, x} end)
  end

  defp dropping_last(:admin, state) do
    board = state.admin_board

    case Board.drop_last(board) do
      {:ok, new_board} ->
        send_update_stats([state.admin_pid])
        {:noreply, %__MODULE__{state | admin_board: new_board}}

      _ ->
        {:noreply, state}
    end
  end

  defp dropping_last(:opponent, state) do
    board = state.opponent_board

    case Board.drop_last(board) do
      {:ok, new_board} ->
        send_update_stats([state.opponent_pid])
        {:noreply, %__MODULE__{state | opponent_board: new_board}}

      _ ->
        {:noreply, state}
    end
  end

  defp dropping_all(:admin, state) do
    new_board = Board.new_board()
    send_update_stats([state.admin_pid])
    {:noreply, %__MODULE__{state | admin_board: new_board}}
  end

  defp dropping_all(:opponent, state) do
    new_board = Board.new_board()
    send_update_stats([state.opponent_pid])
    {:noreply, %__MODULE__{state | opponent_board: new_board}}
  end

  defp compare_state_and_presence(state = %__MODULE__{id: id}) do
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

  defp send_update_stats(pids = [_ | _]) do
    Enum.each(pids, &(&1 && send(&1, :update_state)))
  end
end
