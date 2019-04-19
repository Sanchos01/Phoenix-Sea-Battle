defmodule PhoenixSeaBattle.Saver do
  use GenServer
  @timeout if Mix.env() == :test, do: 100, else: 10_000

  def start_link(), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    :ets.new(:saver, ~w(named_table public set)a)
    {:ok, nil, @timeout}
  end

  def handle_info(:timeout, state) do
    now = :os.system_time(:second)
    :ets.select_delete(:saver, [{{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}])
    {:noreply, state, @timeout}
  end
end
