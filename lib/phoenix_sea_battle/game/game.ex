defmodule PhoenixSeaBattle.Game do
  use ExActor.GenServer
  require Logger
  import PhoenixSeaBattle.Utils, only: [timestamp: 0]
  alias PhoenixSeaBattle.Game.Board
  @reconnect_time 30_000

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

  defstart start_link(name, opts), gen_server_opts: [name: name] do
    id = opts[:id]
    :ok = PhoenixSeaBattle.Endpoint.subscribe("game:" <> id)
    timeout_after(1_000)
    initial_state(%PhoenixSeaBattle.Game{id: id})
  end

  defcall get(), state: state, do: reply({:ok, state})

  defcall add_user(user), state: state = %{id: id, admin: nil} do
    cast_change_user_states(%{user => %{state: 1, gameId: id}})
    {:ok, pid} = Board.start_link(Board, [id: id])
    set_and_reply(%{state | admin: user, admin_board: pid}, {:ok, :admin})
  end
  defcall add_user(user), state: state = %{id: id, admin: admin, opponent: nil} do
    if user != admin do
      cast_change_user_states(%{admin => %{state: 2, with: user}, user => %{state: 2, with: admin}})
      {:ok, pid} = Board.start_link(Board, [id: id])
      set_and_reply(%{state | opponent: user, opponent_board: pid}, {:ok, :opponent})
    else
      reply({:ok, :admin})
    end
  end
  defcall add_user(user), state: %{admin: admin, opponent: opponent} do
    cond do
      user == admin -> reply({:ok, :admin})
      user == opponent -> reply({:ok, :opponent})
      true -> reply({:error, "game already full"})
    end
  end

  defhandleinfo %Phoenix.Socket.Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, state: state = %{id: id, offline: offline, timer: timer} do
    Logger.info("#{inspect id} --- checking diffs - joins: #{inspect joins}, leaves: #{inspect leaves}")
    {offline, timer} = if length(users = Map.keys(leaves)) > 0 do
      {Enum.uniq(offline ++ users), (timer || (timestamp() + @reconnect_time))}
    else
      {offline, timer}
    end
    {offline, timer} = if length(users = Map.keys(joins)) > 0 do
      offline = offline -- users
      {offline, (if offline == [], do: nil, else: timer)}
    else
      {offline, timer}
    end
    new_state(%{state | timer: timer, offline: offline})
  end
  defhandleinfo %Phoenix.Socket.Broadcast{event: "new_msg"}, do: noreply()
  defhandleinfo msg = %Phoenix.Socket.Broadcast{}, state: _state, do: (Logger.info("nothing intresting, msg - #{inspect msg}"); noreply())

  defhandleinfo :timeout, state: %{timer: nil}, do: noreply()
  defhandleinfo :timeout, state: state = %{admin: admin, id: id, opponent: opponent, timer: timer, offline: []}, when: timer do
    Logger.error("timer on, but offline no one")
    PhoenixSeaBattle.Presence.list("game:" <> id)
      |> Map.keys()
      |> (fn users -> [admin, opponent] -- users end).()
      |> case do
        [] -> new_state(put_in(state.timer, nil))
        offline -> new_state(put_in(state.offline, offline))
      end
  end
  defhandleinfo :timeout, state: state = %{id: id, timer: timer} do
    users = [state.admin, state.opponent]
    cond do
      users -- (PhoenixSeaBattle.Presence.list("game:" <> id) |> Map.keys()) == [] -> new_state(%{state | timer: nil})
      timestamp() > timer ->
        Enum.reject(users, fn
          nil -> true
          user -> user in state.offline end)
          |> Enum.reduce(%{}, fn user, acc ->
            Map.put(acc, user, %{state: 3})
          end)
          |> cast_change_user_states()
        stop_server(:normal)
      true -> noreply()
    end
  end

  defcall get_state(_), state: state do
    cond do
      !state.playing -> reply(%{state: "initial"})
      state.ended -> reply(%{state: "game_ended"})
      true -> reply(%{state: "play"})
    end
  end

  defcall readiness(user, body), state: state do
    with true <- validate_board(body)
    do
      case state.admin do
        ^user -> reply(Board.ready(state.admin_board, body))
        _ -> reply(Board.ready(state.opponent_board, body))
      end
    end
  end

  defhandleinfo {:terminate, %PhoenixSeaBattle.User{username: user}}, state: state = %{id: id, admin: admin, opponent: opponent} do
    case user do
      ^admin -> if opponent, do: cast_change_user_states(%{opponent => %{state: 3}})
                stop_server(:normal)
      _ -> cast_change_user_states(%{admin => %{state: 1, gameId: id}})
           new_state(%{state | opponent: nil})
    end
  end

  def terminate(:normal, %{id: id}) do
    PhoenixSeaBattle.Endpoint.broadcast("game:" <> id, "all out", %{})
    Logger.warn("game #{id} stopped")
    :ok
  end
  def terminate(reason, state) do
    Logger.error("Unusual stop game #{inspect state.id} with reason #{inspect reason}, state: #{inspect state}")
    :ok
  end

  defhandleinfo msg, do: (Logger.warn("uncatched message: #{inspect msg}"); noreply())

  defp cast_change_user_states(meta), do: PhoenixSeaBattle.Endpoint.broadcast("room:lobby", "change_state", %{"users" => meta})

  defp validate_board(board) when length(board) == 10 do
    board
    |> List.flatten()
    |> Enum.uniq()
    |> length()
    |> Kernel.==(20)
  end
  defp validate_board(_), do: false
end