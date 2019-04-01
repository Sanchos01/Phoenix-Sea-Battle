defmodule PhoenixSeaBattle.LobbyArchiverTest do
  use ExUnit.Case
  alias PhoenixSeaBattle.LobbyArchiver
  require Logger

  test "subs/0 and new_msg/2" do
    LobbyArchiver.subs()
    body = "Archiver test msg"
    user = "Some User"
    LobbyArchiver.new_msg(body, user)
    msgs = LobbyArchiver.get_messages()

    assert Enum.any?(msgs, fn
             %{body: ^body, user: ^user, timestamp: _} -> true
             _ -> false
           end)

    send(LobbyArchiver, :timeout)
    msgs = LobbyArchiver.get_messages()

    assert Enum.any?(msgs, fn
             %{body: ^body, user: ^user, timestamp: _} -> true
             _ -> false
           end)

    assert_receive {:update, msgs}

    assert Enum.any?(msgs, fn
             %{body: ^body, user: ^user, timestamp: _} -> true
             _ -> false
           end)
  end
end
