defmodule PhoenixSeaBattle.LobbyArchiverTest do
  use ExUnit.Case
  alias PhoenixSeaBattle.LobbyArchiver
  require Logger

  test "subs/0 and new_msg/2" do
    LobbyArchiver.subs()
    body = "hello world"
    user = "SomeUser"
    LobbyArchiver.new_msg(body, user)
    [%{body: ^body, user: ^user, timestamp: _}] = LobbyArchiver.get_messages()
    send LobbyArchiver, :timeout
    [%{body: ^body, user: ^user, timestamp: _}] = LobbyArchiver.get_messages()

    assert_receive {:update, [%{body: ^body, user: ^user, timestamp: _}]}
  end
end
