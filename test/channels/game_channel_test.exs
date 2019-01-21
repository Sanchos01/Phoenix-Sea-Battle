defmodule PhoenixSeaBattle.GameChannelTest do
  use PhoenixSeaBattleWeb.ChannelCase
  alias PhoenixSeaBattleWeb.{UserSocket, GameChannel}

  setup do
    {:ok, _, socket} = UserSocket
      |> socket("user_id", %{user: "abc", user_id: 777})
      |> subscribe_and_join(GameChannel, "game:12345678")

    {:ok, socket: socket}
  end
  
  test "new message broadcast to game:*", %{socket: socket} do
    push socket, "new_msg", %{"body" => "hi there"}
    assert_broadcast "new_msg", %{body: "hi there"}, 1_000
  end
end
