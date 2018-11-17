defmodule PhoenixSeaBattle.RoomChannelTest do
  use PhoenixSeaBattleWeb.ChannelCase
  alias PhoenixSeaBattleWeb.{UserSocket, RoomChannel}
  @valid_id "12345678"

  setup_all do
    PhoenixSeaBattle.Game.Supervisor.new_game(@valid_id)
    :ok
  end

  setup config do
    if username = config[:login_as] do
      %{id: user_id} = insert_user(%{username: username, password: "secret"})
      {:ok, _, in_lobby_socket} =
        socket(UserSocket, "user_id", %{user_id: user_id, user: username})
        |> subscribe_and_join(RoomChannel, "room:lobby")
      {:ok, _, in_game_socket} =
        socket(UserSocket, "user_id", %{user_id: user_id, user: username})
        |> subscribe_and_join(RoomChannel, "room:lobby", %{"game" => @valid_id})
      {:ok, in_game_socket: in_game_socket, in_lobby_socket: in_lobby_socket, user: username}
    else
      :ok
    end
  end

  @tag login_as: "max123"
  test "new message broadcasts to room:lobby", %{in_lobby_socket: socket, user: username} do
    push socket, "new_msg", %{"body" => "hi there"}
    assert_broadcast "new_msg", %{body: "hi there", user: ^username}, 1_000
  end

  @tag login_as: "max123"
  test "broadcasts are pushed to the client", %{in_lobby_socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}, 1_000
  end
end
