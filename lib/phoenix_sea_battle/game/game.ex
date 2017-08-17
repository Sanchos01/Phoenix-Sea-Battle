defmodule PhoenixSeaBattle.Game do
  use ExActor.GenServer
  require Logger

  defstruct [
    id: nil,
    admin: nil,
    opponent: nil,
    playing: false,
    ended: false,
    winner: nil
  ]

  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    id = opts[:id]
    :ok = PhoenixSeaBattle.Endpoint.subscribe("game:" <> id)
    initial_state([gamestate: %PhoenixSeaBattle.Game{id: id}])
  end

  defcall get(), state: state do
    reply({:ok, state})
  end

  defcall add_user(user), state: [gamestate: gamestate = %{id: id, admin: nil}] do
    cast_change_user_states(%{user => %{state: 1, gameId: id}})
    set_and_reply([gamestate: %{gamestate | admin: user}], {:ok, :admin})
  end
  defcall add_user(user), state: [gamestate: gamestate = %{admin: admin, opponent: nil}] do
    if user != admin do
      cast_change_user_states(%{admin => %{state: 2, with: user}, user => %{state: 2, with: admin}})
      set_and_reply([gamestate: %{gamestate | opponent: user}], {:ok, :opponent})
    else
      reply({:ok, :admin})
    end
  end
  defcall add_user(user), state: [gamestate: %{admin: admin, opponent: opponent}] do
    cond do
      user == admin -> reply({:ok, :admin})
      user == opponent -> reply({:ok, :opponent})
      true -> reply({:error, "game already full"})
    end
  end

  defhandleinfo %Phoenix.Socket.Broadcast{event: "presence_diff", payload: %{joins: joins, leaves: leaves}} do
    Logger.warn("checking diffs - joins: #{inspect joins}, leaves: #{inspect leaves}")
    noreply()
  end

  defhandleinfo {:terminate, %PhoenixSeaBattle.User{username: user}}, state: state = [gamestate: %{id: id, admin: admin, opponent: opponent}] do
    case user do
      ^admin -> if opponent, do: cast_change_user_states(%{opponent => %{state: 3}})
                PhoenixSeaBattle.Endpoint.broadcast("game:" <> id, "all out", %{})
                stop_server(:normal)
      _ -> cast_change_user_states(%{admin => %{state: 1, gameId: id}})
           new_state(put_in(state[:gamestate].opponent, nil))
    end
  end
  defhandleinfo msg, do: (Logger.warn("uncatched message: #{inspect msg}"); noreply())

  defp cast_change_user_states(meta) do
    PhoenixSeaBattle.Endpoint.broadcast("room:lobby", "change_state", %{"users" => meta})
  end
end