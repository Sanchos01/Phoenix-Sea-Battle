defmodule PhoenixSeaBattle.Game.Supervisor do
  use DynamicSupervisor
  alias PhoenixSeaBattle.Game

  def start_link, do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def new_game(id) do
    start = {Game, :start_link, [via_tuple(id), [id: id]]}
    spec = %{id: via_tuple(id), start: start, restart: :transient}
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def via_tuple(name), do: {:via, Registry, {PhoenixSeaBattle.Game.Registry, "game:" <> name}}
end
