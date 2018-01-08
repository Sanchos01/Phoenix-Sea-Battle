defmodule PhoenixSeaBattle.LobbyArchiver do
  use GenServer
  require Logger
  alias Phoenix.Socket.Broadcast
  @msg_count Application.get_env(:phoenix_sea_battle, :msg_count)
  @timeout 1_000

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    PhoenixSeaBattleWeb.Endpoint.subscribe("room:lobby")
    Process.send_after(self(), :timeout, @timeout)
    {:ok, []}
  end

  def get_messages(ts), do: GenServer.call(__MODULE__, {:get, ts})
  def handle_call({:get, ts}, _from, state) do
    new_state = Enum.take(state, @msg_count)
    {:reply, filter_messages(new_state, ts), new_state}
  end

  def handle_info(:timeout, state) do
    Process.send_after(self(), :timeout, @timeout)
    {:noreply, Enum.take(state, @msg_count)}
  end

  def handle_info(%Broadcast{event: "new_msg", payload: msg = %{}}, state), do: {:noreply, [msg | state]}
  def handle_info(%Broadcast{}, state), do: {:noreply, state}

  def handle_info(msg, state), do: (Logger.warn("some msg for archiver: #{inspect msg}"); {:noreply, state})

  def filter_messages(messages, ts, acc \\ [])
  def filter_messages([], _ts, acc), do: acc
  def filter_messages([msg|rest], ts, acc) do
    case msg.timestamp > ts do
      true -> filter_messages(rest, ts, [msg|acc])
      _ -> acc
    end
  end
end