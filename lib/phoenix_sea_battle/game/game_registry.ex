defmodule PhoenixSeaBattle.Game.Registry do
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end
end
