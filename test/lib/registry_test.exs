defmodule PhoenixSeaBattle.Game.RegistryTest do
  use ExUnit.Case, async: true
  alias PhoenixSeaBattle.Game.Registry, as: GameRegistry

  test "Registry module" do
    assert GenServer.whereis(GameRegistry)
    assert {:error, _} = GameRegistry.start_link()
  end
end
