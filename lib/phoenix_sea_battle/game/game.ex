defmodule PhoenixSeaBattle.Game do
  use GenServer
  require Logger
  alias PhoenixSeaBattle.Game.Board
  alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.{Endpoint, Presence}
  @reconnect_time Application.get_env(:phoenix_sea_battle, :reconnect_time, 30_000)
  @timeout 1_000

  defstruct [
    id: nil,
    admin: nil,
    opponent: nil,
    admin_board: nil,
    opponent_board: nil,
    playing: false,
    ended: false,
    winner: nil,
    timer: nil,
    offline: []
  ]

  def start_link(name, opts) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init([id: id]) do
    :ok = Endpoint.subscribe("game:" <> id)
    Process.send_after(self(), :timeout, @timeout) # TODO check timeout
    {:ok, %__MODULE__{id: id}}
  end
  def init(_), do: {:stop, "No id"}

  def get(pid),                   do: GenServer.call(pid, :get)
  def get_state(pid),             do: GenServer.call(pid, :get_state)
  def add_user(pid, user),        do: GenServer.call(pid, {:add_user, user})
  def readiness(pid, user, body), do: GenServer.call(pid, {:readiness, user, body})

  # Calls
  # get
  def handle_call(:get, _from, state), do: {:reply, {:ok, state}, state}

  # add_user
  def handle_call({:add_user, user}, _from, state = %{id: id, admin: nil}) do
    cast_change_user_states(%{user => %{state: 1, gameId: id}})
    {:reply, {:ok, :admin}, %{state | admin: user, admin_board: %Board{}}}
  end
  def handle_call({:add_user, user}, _from, state = %{admin: admin, opponent: nil}) do
    if user != admin do
      %{admin => %{state: 2, with: user}, user => %{state: 2, with: admin}}
      |> cast_change_user_states()
      {:reply, {:ok, :opponent}, %{state | opponent: user, opponent_board: %Board{}}}
    else
      {:reply, {:ok, :admin}, state}
    end
  end
  def handle_call({:add_user, user}, _from, state = %{admin: admin, opponent: opponent}) do
    case user do
      ^admin    -> {:reply, {:ok, :admin}, state}
      ^opponent -> {:reply, {:ok, :opponent}, state}
      _         -> {:reply, {:error, "game already full"}, state}
    end
  end

  # get_state
  def handle_call(:get_state, _from, state) do
    cond do
      !state.playing -> {:reply, %{state: "initial"}, state}
      state.ended    -> {:reply, %{state: "game_ended"}, state}
      true           -> {:reply, %{state: "play"}, state}
    end
  end

  # readiness
  def handle_call({:readiness, user, body}, _from, state) do # TODO rework this func, especially await liveView
    with board = %Board{} <- Board.new(body) do
      new_state = case state.admin do
        ^user -> %{state | admin_board: board}
        _     -> %{state | opponent_board: board}
      end
      if ready_to_start(new_state) do
        Logger.info "start game #{inspect state.id}"
        {:reply, :start, new_state}
      else
        {:reply, :ok, new_state}
      end
    else
      error -> {:reply, error, state}
    end
  end

  # Infos
  def handle_info(%Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, state = %{id: id, offline: offline, timer: timer}) do
    Logger.debug "#{inspect id} --- checking diffs - joins: #{inspect joins}, leaves: #{inspect leaves}"

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
  def handle_info(%Broadcast{event: "new_msg"}, state), do: {:noreply, state}
  def handle_info(msg = %Broadcast{}, state) do
    Logger.info("nothing intresting, msg - #{inspect msg}")
    {:noreply, state}
  end

  def handle_info(:timeout, state = %{timer: nil}), do: {:noreply, state}
  def handle_info(:timeout, state = %{admin: admin, id: id, opponent: opponent, timer: timer, offline: []}) when timer != nil do
    Logger.error("timer on, but offline no one")
    ("game:" <> id)
    |> Presence.list()
    |> Map.keys()
    |> (fn users -> [admin, opponent] -- users end).()
    |> case do
      []      -> {:noreply, put_in(state.timer, nil)}
      offline -> {:noreply, put_in(state.offline, offline)}
    end
  end
  def handle_info(:timeout, state = %{id: id, timer: timer}) do
    users = [state.admin, state.opponent]
    cond do
      users -- (("game:" <> id) |> Presence.list() |> Map.keys()) == [] -> {:noreply, %{state | timer: nil}}
      System.system_time(:second) > timer ->
        users
        |> Enum.reject(fn
          nil  -> true
          user -> user in state.offline
        end)
        |> Enum.reduce(%{}, fn user, acc ->
          Map.put(acc, user, %{state: 3})
        end)
        |> cast_change_user_states()
        {:stop, :normal, state}
      true -> {:noreply, state}
    end
  end

  def handle_info({:terminate, user}, state = %{id: id, admin: admin, opponent: opponent}) do
    case user do
      ^admin -> if opponent, do: cast_change_user_states(%{opponent => %{state: 3}})
                {:stop, :normal, state}
      _ -> cast_change_user_states(%{admin => %{state: 1, gameId: id}})
           {:noreply, %{state | opponent: nil}}
    end
  end

  def handle_info(msg, state) do
    Logger.warn("uncatched message: #{inspect msg}")
    {:noreply, state}
  end

  def terminate(:normal, %{id: id}) do
    Endpoint.broadcast("game:" <> id, "all out", %{})
    Logger.warn("game #{id} stopped")
    :ok
  end
  def terminate(reason, state) do
    Logger.error("Unusual stop game #{inspect state.id} with reason #{inspect reason}, state: #{inspect state}")
    :ok
  end

  defp cast_change_user_states(meta), do: Endpoint.broadcast("room:lobby", "change_state", %{"users" => meta})

  defp ready_to_start(%{admin_board: nil}), do: false
  defp ready_to_start(%{opponent_board: nil}), do: false
  defp ready_to_start(%{admin_board: admin_board, opponent_board: opponent_board}) do
    Board.valid?(admin_board) && Board.valid?(opponent_board)
  end
end
