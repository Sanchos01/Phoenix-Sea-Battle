defmodule PhoenixSeaBattle.LobbyArchiverTest do
  use ExUnit.Case
  alias PhoenixSeaBattle.LobbyArchiver
  require Logger

  setup config do
    if config[:msgs] do
      now = System.system_time(:milliseconds)
      msgs = [
        %{body: "msg 1", timestamp: now + 10_000, user: "max123"},
        %{body: "msg 2", timestamp: now + 5_000, user: "max123"},
        %{body: "msg 3", timestamp: now - 5_000, user: "max123"},
        %{body: "msg 4", timestamp: now - 10_000, user: "max123"},
      ]
      {:ok, msgs: msgs}
    else
      :ok
    end
  end

  test ":timeout", do: assert send(LobbyArchiver, :timeout)
  test "some msg", do: assert send(LobbyArchiver, "some msg")

  @tag :msgs
  test "filter_messages", %{msgs: msgs} do
    assert (LobbyArchiver.filter_messages(msgs, System.system_time(:milliseconds)) |> length()) == 2
  end
end