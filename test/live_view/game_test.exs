defmodule PhoenixSeaBattleWeb.GameTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias Phoenix.LiveViewTest
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game, as: GameServer
  alias PhoenixSeaBattleWeb.Game, as: GameLive
  alias PhoenixSeaBattleWeb.Endpoint

  describe "connection" do
    setup do
      user1 = insert_user(%{name: "user1"})
      user2 = insert_user(%{name: "user2"})
      <<id::binary-8, _::binary>> = Ecto.UUID.generate()
      GameSupervisor.new_game(id)
      {:ok, %{user1: user1, user2: user2, id: id}}
    end

    test "add admin, opponent, third player can't connect", %{user1: user1, user2: user2, id: id} do
      token = Phoenix.Controller.get_csrf_token()

      {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
      params = [session: %{user: user1, id: id, token: token}]
      {:ok, %LiveViewTest.View{}, _} = LiveViewTest.mount(Endpoint, GameLive, params)

      {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
      params = [session: %{user: user2, id: id, token: token}]
      {:ok, %LiveViewTest.View{}, _} = LiveViewTest.mount(Endpoint, GameLive, params)

      user3 = insert_user(%{name: "user3"})
      {:error, "game already full"} = GameServer.add_user(GameSupervisor.via_tuple(id), user3)
      params = [session: %{user: user3, id: id, token: token}]
      # User will be redirected to GET /game/:id
      path = "/game/#{id}"
      assert {:ok, _, _} = LiveViewTest.mount_disconnected(Endpoint, GameLive, params)
      assert {:error, %{redirect: ^path}} = LiveViewTest.mount(Endpoint, GameLive, params)
    end
  end

  describe "initial" do
    setup do
      user1 = insert_user(%{name: "user1"})
      user2 = insert_user(%{name: "user2"})
      <<id::binary-8, _::binary>> = Ecto.UUID.generate()
      GameSupervisor.new_game(id)

      {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
      token = Phoenix.Controller.get_csrf_token()
      params = [session: %{user: user1, id: id, token: token}]
      {:ok, view1, _html} = LiveViewTest.mount(Endpoint, GameLive, params)

      {:ok, %{id: id, user1: user1, user2: user2, view1: view1}}
    end

    test "render board while placing ships", %{view1: view} do
      assert LiveViewTest.render(view) =~
               ~r/<div class=\"board\">[\n\s]*<div class=\"block ghost_block\">/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowDown") =~
               ~r/<div class=\"board\">([\n\s]*<div class=\"block\">\n<\/div>[\n\s]*){10}<div class=\"block ghost_block\">/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowRight") =~
               ~r/<div class=\"board\">([\n\s]*<div class=\"block\">\n<\/div>[\n\s]*){11}<div class=\"block ghost_block\">/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowLeft") =~
               ~r/<div class=\"board\">([\n\s]*<div class=\"block\">\n<\/div>[\n\s]*){10}<div class=\"block ghost_block\">/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowUp") =~
               ~r/<div class=\"board\">[\n\s]*<div class=\"block ghost_block\">/

      refute LiveViewTest.render_keydown(view, "keydown", "+") =~
               "<div class=\"block ship_block\">"

      :timer.sleep(20)
      html = LiveViewTest.render(view)
      assert html =~ "<div class=\"block ship_block\">"
      assert html =~ ~r/(<div class=\"block cross_block\">\n<\/div>[\n\s]*){3}/
    end

    test "render error messages", %{view1: view} do
      assert LiveViewTest.render(view) =~ "Move your ships with arrows"
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(20)
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(20)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't cross"
      LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(20)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
      :timer.sleep(100)
      refute LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
    end

    test "render opponent status", %{view1: view1, id: id, user2: user2} do
      assert LiveViewTest.render(view1) =~ "No opponent"
      {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
      token = Phoenix.Controller.get_csrf_token()
      params = [session: %{user: user2, id: id, token: token}]
      {:ok, _view2, _html} = LiveViewTest.mount(Endpoint, GameLive, params)
      :timer.sleep(20)
      assert LiveViewTest.render(view1) =~ "Opponent: #{user2.name}"
    end
  end
end
