defmodule PhoenixSeaBattle.RoomChannelTest do
  use PhoenixSeaBattle.ChannelCase
  alias PhoenixSeaBattle.RoomChannel

  setup config do
    if username = config[:login_as] do
      user = insert_user(%{username: username, password: "secret"})
      {:ok, _, in_lobby_socket} =
        socket("user_id", %{user_id: Map.get(user, :id), user: Map.get(user, :username)})
        |> subscribe_and_join(RoomChannel, "room:lobby")
      {:ok, _, in_game_socket} =
        socket("user_id", %{user_id: Map.get(user, :id), user: Map.get(user, :username)})
        |> subscribe_and_join(RoomChannel, "room:lobby", %{"game" => "12345678"})
      {:ok, in_game_socket: in_game_socket, in_lobby_socket: in_lobby_socket, user: Map.get(user, :username)}
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
