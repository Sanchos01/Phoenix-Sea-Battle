defmodule PhoenixSeaBattle.LobbyArchiver do
  use GenServer
  require Logger
  @msg_count Application.get_env(:phoenix_sea_battle, :msg_count)
  @timeout 1_000

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :timeout, @timeout)
    {:ok, %{msg: [], subs: []}}
  end

  def get_messages(ts \\ 0) when is_integer(ts), do: GenServer.call(__MODULE__, {:get, ts})
  def subs(), do: GenServer.call(__MODULE__, :subs)
  def new_msg(msg, user), do: GenServer.cast(__MODULE__, {:new_msg, msg, user})

  def handle_cast({:new_msg, body, user}, state) do
    new_msg = %{body: body, user: user, timestamp: :os.system_time(:second)}
    new_msgs = [new_msg | Enum.take(state.msg, @msg_count)]
    Enum.each(state.subs, fn pid -> send pid, {:update, Enum.reverse(new_msgs)} end)
    {:noreply, %{state | msg: new_msgs}}
  end

  def handle_call({:get, ts}, _from, state) do
    reply = get_msgs(state, ts)
    {:reply, reply, state}
  end

  def handle_call(:subs, {pid, _ref}, state) do
    Process.monitor(pid)
    msgs = get_msgs(state)
    {:reply, {:ok, msgs}, update_in(state.subs, & [pid | &1])}
  end

  def handle_info(:timeout, state) do
    Process.send_after(self(), :timeout, @timeout)
    {:noreply, update_in(state.msg, & Enum.take(&1, @msg_count))}
  end
  
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, update_in(state.subs, & Enum.reject(&1, fn x -> x == pid end))}
  end

  defp get_msgs(state, ts \\ 0) do
    Enum.reduce(state.msg, [], & (if &1.timestamp > ts, do: [&1 | &2], else: &2))
  end
end
