defmodule PhoenixSeaBattle.GameChannelTest do
  use PhoenixSeaBattle.ChannelCase

  alias PhoenixSeaBattle.GameChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(GameChannel, "game:12345678")

    {:ok, socket: socket}
  end
  
  test "new message broadcast to game:*", %{socket: socket} do
    push socket, "new_msg", %{"body" => "hi there"}
    assert_broadcast "new_msg", %{body: "hi there"}, 2_000
  end
end
