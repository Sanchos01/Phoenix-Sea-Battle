defmodule PhoenixSeaBattle.RoomChannelTest do
  use PhoenixSeaBattle.ChannelCase

  alias PhoenixSeaBattle.RoomChannel
  alias PhoenixSeaBattle.Repo
  alias PhoenixSeaBattle.User

  setup do
    {:ok, _, anon_socket} =
      socket("user_id", %{anonymous: Ecto.UUID.generate()})
      |> subscribe_and_join(RoomChannel, "room:lobby")
    query = from u in User,
    select: u.id
    user_id = Repo.all(query) |> List.first
    username = Repo.get(PhoenixSeaBattle.User, user_id).username
    {:ok, _, auth_socket} =
      socket("user_id", %{user_id: user_id})
      |> subscribe_and_join(RoomChannel, "room:lobby")

    {:ok, socket: [anon_socket, {auth_socket, username}]}
  end

  test "new message broadcasts to room:lobby", %{socket: sockets} do
    Enum.map(sockets, fn
      {auth_socket, username} ->
        push auth_socket, "new_msg", %{"body" => "hi there"}
        assert_broadcast "new_msg", %{body: "hi there", user: ^username}
      anon_socket ->
        push anon_socket, "new_msg", %{"body" => "hi there"}
        assert_broadcast "new_msg", %{body: "hi there", user: "Anon:" <> _}
      end
    )
  end

  # test "new message broadcasts to room:lobby", %{socket: [anon_socket, auth_socket]} do
  #   push anon_socket, "new_msg", %{"body" => "hi there"}
  #   assert_broadcast "new_msg", %{body: "hi there"}
  #   push auth_socket, "new_msg", %{"body" => "hi there"}
  #   assert_broadcast "new_msg", %{body: "hi there", username: "123"}
  #   # Enum.map(sockets, fn socket ->
  #   #   push socket, "new_msg", %{"body" => "hi there"}
  #   #   assert_broadcast "new_msg", %{body: "hi there"}
  #   # end)
  # end

  test "broadcasts are pushed to the client", %{socket: sockets} do
    Enum.map(sockets, fn
      {auth_socket, _username} ->
        broadcast_from! auth_socket, "broadcast", %{"some" => "data"}
        assert_push "broadcast", %{"some" => "data"}
      anon_socket ->
        broadcast_from! anon_socket, "broadcast", %{"some" => "data"}
        assert_push "broadcast", %{"some" => "data"}
      end
    )
  end
end
