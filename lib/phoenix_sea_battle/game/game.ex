defmodule PhoenixSeaBattle.Game do
  use ExActor.GenServer
  require Logger

  defstruct [
    id: nil,
    admin: nil,
    opponent: nil,
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
    PhoenixSeaBattle.Endpoint.broadcast("room:lobby", "change_state", %{"users" => %{user => %{state: 1, gameId: id}}})
    set_and_reply([gamestate: %{gamestate | admin: user}], :ok)
  end
  defcall add_user(user), state: [gamestate: gamestate = %{admin: admin, opponent: nil}] do
    PhoenixSeaBattle.Endpoint.broadcast("room:lobby", "change_state", %{"users" => %{admin => %{state: 2, with: user}, user => %{state: 2, with: admin}}})
    set_and_reply([gamestate: %{gamestate | opponent: user}], :ok)
  end
  defcall add_user(user), state: [gamestate: %{admin: admin, opponent: opponent}] do
    if user == admin || user == opponent do
      reply(:ok)
    else
      reply({:error, "game already full"})
    end
  end

  defhandleinfo :terminate, state: [gamestate: %{id: id}] do
    PhoenixSeaBattle.Endpoint.broadcast("game:" <> id, "all out", %{})
    stop_server(:normal)
  end
  defhandleinfo _, do: noreply()
end