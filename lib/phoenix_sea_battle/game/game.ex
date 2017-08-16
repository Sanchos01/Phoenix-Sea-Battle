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
    initial_state([gamestate: %PhoenixSeaBattle.Game{id: opts[:id]}])
  end

  defcall get(), state: state do
    reply({:ok, state})
  end
end