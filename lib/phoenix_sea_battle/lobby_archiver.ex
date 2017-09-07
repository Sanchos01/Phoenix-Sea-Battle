defmodule PhoenixSeaBattle.LobbyArchiver do
  use ExActor.GenServer
  require Logger
  @msg_count Application.get_env(:phoenix_sea_battle, :msg_count)

  defstart start_link, gen_server_opts: [name: __MODULE__] do
    PhoenixSeaBattle.Endpoint.subscribe("room:lobby")
    timeout_after(1_000)
    initial_state([])
  end

  defcall get_messages(ts), state: state do
    new_state = Enum.take(state, @msg_count)
    set_and_reply(new_state, filter_messages(new_state, ts))
  end

  defhandleinfo :timeout, state: state, do: new_state(Enum.take(state, @msg_count))

  defhandleinfo %Phoenix.Socket.Broadcast{event: "new_msg", payload: msg = %{}}, state: state, do: new_state([msg | state])
  defhandleinfo %Phoenix.Socket.Broadcast{}, do: noreply()

  defhandleinfo msg, do: (Logger.warn("some msg for archiver: #{inspect msg}"); noreply())

  def filter_messages(messages, ts, acc \\ [])
  def filter_messages([], _ts, acc), do: acc
  def filter_messages([msg|rest], ts, acc) do
    case msg.timestamp > ts do
      true -> filter_messages(rest, ts, [msg|acc])
      _ -> acc
    end
  end
end