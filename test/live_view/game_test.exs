defmodule PhoenixSeaBattleWeb.GameTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias Phoenix.LiveViewTest
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  alias PhoenixSeaBattleWeb.Game, as: GameLive
  alias PhoenixSeaBattleWeb.Endpoint

  setup do
    user1 = insert_user(%{name: "user1"})
    user2 = insert_user(%{name: "user2"})
    <<id::binary-8, _::binary>> = Ecto.UUID.generate()
    GameSupervisor.new_game(id)
    {:ok, %{user1: user1, user2: user2, id: id}}
  end

  test "add admin, opponent, third player can't connect", %{user1: user1, user2: user2, id: id} do
    {:ok, :admin} = Game.add_user(GameSupervisor.via_tuple(id), user1)

    {:ok, %LiveViewTest.View{}, _html} =
      LiveViewTest.mount_disconnected(Endpoint, GameLive, session: %{user: user1, id: id})

    {:ok, :opponent} = Game.add_user(GameSupervisor.via_tuple(id), user2)

    {:ok, %LiveViewTest.View{}, _html} =
      LiveViewTest.mount_disconnected(Endpoint, GameLive, session: %{user: user2, id: id})

    user3 = insert_user(%{name: "user3"})
    {:error, "game already full"} = Game.add_user(GameSupervisor.via_tuple(id), user3)

    assert {:error, %{redirect: "/"}} =
             LiveViewTest.mount_disconnected(Endpoint, GameLive, session: %{user: user3, id: id})
  end
end
