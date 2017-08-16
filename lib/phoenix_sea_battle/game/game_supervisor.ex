defmodule PhoenixSeaBattle.Game.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(PhoenixSeaBattle.Game, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def new_game(id) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_tuple(id), [id: id]])
  end

  def via_tuple(name) do
    {:via, Registry, {PhoenixSeaBattle.Game.Registry, "game:" <> name}}
  end
end