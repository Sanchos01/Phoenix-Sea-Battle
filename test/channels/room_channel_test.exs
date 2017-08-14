defmodule PhoenixSeaBattle.RoomChannelTest do
  use PhoenixSeaBattle.ChannelCase

  alias PhoenixSeaBattle.RoomChannel
  alias PhoenixSeaBattle.Repo
  alias PhoenixSeaBattle.User

  setup do
    query = from u in User,
    select: u.id
    user_id = Repo.all(query) |> List.first
    username = Repo.get(PhoenixSeaBattle.User, user_id).username
    {:ok, _, auth_socket} =
      socket("user_id", %{user_id: user_id})
      |> subscribe_and_join(RoomChannel, "room:lobby")

    {:ok, socket: auth_socket, user: username}
  end

  test "new message broadcasts to room:lobby", %{socket: socket, user: username} do
    push socket, "new_msg", %{"body" => "hi there"}
    assert_broadcast "new_msg", %{body: "hi there", user: ^username}, 2_000
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}, 2_000
  end
end
