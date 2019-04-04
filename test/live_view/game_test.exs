defmodule PhoenixSeaBattleWeb.GameTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias Phoenix.LiveViewTest
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game, as: GameServer
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
    {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
    token = Phoenix.Controller.get_csrf_token()
    params = [session: %{user: user1, id: id, token: token}]

    {:ok, %LiveViewTest.View{}, _html} =
      LiveViewTest.mount_disconnected(Endpoint, GameLive, params)

    {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
    params = [session: %{user: user2, id: id, token: token}]

    {:ok, %LiveViewTest.View{}, _html} =
      LiveViewTest.mount_disconnected(Endpoint, GameLive, params)

    user3 = insert_user(%{name: "user3"})
    {:error, "game already full"} = GameServer.add_user(GameSupervisor.via_tuple(id), user3)
    params = [session: %{user: user3, id: id, token: token}]

    # User will be redirected to GET /game/:id
    path = "/game/#{id}"
    assert {:error, %{redirect: ^path}} = LiveViewTest.mount(Endpoint, GameLive, params)
  end
end
