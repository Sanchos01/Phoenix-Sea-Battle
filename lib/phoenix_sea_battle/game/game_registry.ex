defmodule PhoenixSeaBattle.Game.Registry do
  def start_link do
    Registry.start_link(:unique, __MODULE__)
  end
end