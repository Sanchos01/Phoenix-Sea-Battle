defmodule PhoenixSeaBattleWeb.GameTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true
  require Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.GameServer
  alias PhoenixSeaBattleWeb.Game, as: GameLive
  alias PhoenixSeaBattleWeb.Endpoint

  @ghost_block "[\n\s\r]*<div class=\"block ghost_block\">\n<\/div>"
  @board_class "[\n\s\r]*<div class=\"board\">"
  @some_blocks "[\n\s\r]*<div class=\"block\">\n<\/div>"
  @vertical_repeatence "#{@ghost_block}(#{@some_blocks}){9}"

  defp count_ship_blocks(html) do
    pattern = :binary.compile_pattern([" ", "\\", "\""])

    html
    |> String.splitter(pattern)
    |> Enum.reduce(0, fn
      x, acc when x in ~w(cross_block ship_block) -> acc + 1
      _, acc -> acc
    end)
  end

  defp mount_view(id, user) do
    {:ok, state} = GameServer.add_user(GameSupervisor.via_tuple(id), user)
    token = Phoenix.Controller.get_csrf_token()
    params = [session: %{user: user, id: id, token: token}]
    {:ok, view, _html} = LiveViewTest.mount(Endpoint, GameLive, params)
    {:ok, view, state}
  end

  @ships [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]
  @xs List.duplicate(0, 5) ++ List.duplicate(5, 5)
  @ys [0, 2, 4, 6, 8] |> List.duplicate(2) |> List.flatten()
  @ships_with_places Enum.zip(@ships, Enum.zip(@xs, @ys))
  defp fill_board(view, ships_count \\ 10) do
    %{user: %{id: user_id}, pid: pid} = :sys.get_state(view.pid).socket.assigns

    @ships_with_places
    |> Enum.take(ships_count)
    |> Enum.each(fn {l, {x, y}} ->
      GameServer.apply_ship(pid, user_id, %{x: x, y: y, pos: :h, l: l})
    end)

    :timer.sleep(10)
    html = LiveViewTest.render(view)
    count = @ships |> Enum.take(ships_count) |> Enum.sum()
    ^count = count_ship_blocks(html)
    html
  end

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
      {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
      params = [session: %{user: user1, id: id, token: token}]
      {:ok, %LiveViewTest.View{}, _} = LiveViewTest.mount(Endpoint, GameLive, params)

      {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
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

  describe "game" do
    setup do
      user1 = insert_user(%{name: "user1"})
      user2 = insert_user(%{name: "user2"})
      <<id::binary-8, _::binary>> = Ecto.UUID.generate()
      GameSupervisor.new_game(id)
      {:ok, view1, :admin} = mount_view(id, user1)
      {:ok, %{id: id, user1: user1, user2: user2, view1: view1}}
    end

    test "render board while placing ships", %{view1: view} do
      assert LiveViewTest.render(view) =~ ~r/#{@board_class}[\n\s]*#{@ghost_block}/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowDown") =~
               ~r/#{@board_class}(#{@some_blocks}){10}#{@ghost_block}/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowRight") =~
               ~r/#{@board_class}(#{@some_blocks}){11}#{@ghost_block}/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowLeft") =~
               ~r/#{@board_class}(#{@some_blocks}){10}#{@ghost_block}/

      assert LiveViewTest.render_keydown(view, "keydown", "ArrowUp") =~
               ~r/#{@board_class}[\n\s]*#{@ghost_block}/

      refute LiveViewTest.render_keydown(view, "keydown", "+") =~
               "<div class=\"block ship_block\">"

      :timer.sleep(10)
      html = LiveViewTest.render(view)
      assert html =~ "<div class=\"block ship_block\">"
      assert html =~ ~r/(<div class=\"block cross_block\">\n<\/div>[\n\s]*){3}/
    end

    test "render board while moving ghost (horizontal)", %{view1: view} do
      html = LiveViewTest.render(view)
      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowUp")
      assert html == new_html
      assert new_html =~ ~r/(#{@ghost_block}[\n\s]*){4}/

      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowLeft")
      assert html == new_html
      assert new_html =~ ~r/(#{@ghost_block}[\n\s]*){4}/

      html =
        Enum.reduce(1..6, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
      assert html == new_html
      assert new_html =~ ~r/(#{@ghost_block}[\n\s]*){4}/

      html =
        Enum.reduce(1..9, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
      assert html == new_html
      assert new_html =~ ~r/(#{@ghost_block}[\n\s]*){4}/
    end

    test "render board while moving ghost (vertical)", %{view1: view} do
      html = LiveViewTest.render_keydown(view, "keydown", "-")
      assert html =~ ~r/#{@board_class}(#{@vertical_repeatence}){4}#{@some_blocks}/

      assert html == LiveViewTest.render_keydown(view, "keydown", "ArrowUp")
      assert html == LiveViewTest.render_keydown(view, "keydown", "ArrowLeft")

      html =
        Enum.reduce(1..9, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
      assert html == new_html
      assert new_html =~ ~r/#{@board_class}(#{@some_blocks}){9}(#{@vertical_repeatence}){4}/

      html =
        Enum.reduce(1..6, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
      assert html == new_html
      reg = ~r/#{@board_class}(#{@some_blocks}){69}(#{@vertical_repeatence}){3}#{@ghost_block}/
      assert new_html =~ reg
    end

    test "rotate ghost on board", %{view1: view} do
      h_reg = ~r/#{@board_class}(#{@some_blocks}){66}(#{@ghost_block}[\n\s]*){4}/
      v_reg = ~r/#{@board_class}(#{@some_blocks}){66}(#{@vertical_repeatence}){3}#{@ghost_block}/

      html =
        Enum.reduce(1..9, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
          LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "-")
      refute html == new_html
      assert new_html =~ v_reg

      html =
        Enum.reduce(1..3, "", fn _, _ ->
          LiveViewTest.render_keydown(view, "keydown", "ArrowRight")
        end)

      new_html = LiveViewTest.render_keydown(view, "keydown", "-")
      refute html == new_html
      assert new_html =~ h_reg

      html = LiveViewTest.render_keydown(view, "keydown", "-")
      assert html =~ v_reg

      html = LiveViewTest.render_keydown(view, "keydown", "-")
      assert html =~ h_reg
    end

    test "render error messages (admin)", %{view1: view} do
      assert LiveViewTest.render(view) =~ "Move your ships with arrows"
      LiveViewTest.render_keydown(view, "keydown", "+")
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(10)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't cross"
      LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(10)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
      :timer.sleep(100)
      refute LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
    end

    test "render error messages (opponent)", %{user2: user, id: id} do
      {:ok, view, :opponent} = mount_view(id, user)

      assert LiveViewTest.render(view) =~ "Move your ships with arrows"
      LiveViewTest.render_keydown(view, "keydown", "+")
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(10)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't cross"
      LiveViewTest.render_keydown(view, "keydown", "ArrowDown")
      LiveViewTest.render_keydown(view, "keydown", "+")
      :timer.sleep(10)
      assert LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
      :timer.sleep(100)
      refute LiveViewTest.render(view) =~ "<div class=\"error\">\nShips shouldn't touch"
    end

    test "render opponent status", %{view1: view1, id: id, user2: user2} do
      assert LiveViewTest.render(view1) =~ "No opponent"
      {:ok, _, :opponent} = mount_view(id, user2)
      :timer.sleep(10)
      assert LiveViewTest.render(view1) =~ "Opponent: #{user2.name}"
    end

    test "apply ships, drop last and drop all (admin)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)
      fill_board(view2)
      html = fill_board(view1, 4)
      assert 12 == count_ship_blocks(html)

      LiveViewTest.render_click(view1, "drop_last")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert 10 == count_ship_blocks(html)

      LiveViewTest.render_click(view2, "ready")
      LiveViewTest.render_click(view1, "drop_last")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert 7 == count_ship_blocks(html)

      LiveViewTest.render_click(view2, "unready")
      LiveViewTest.render_click(view1, "drop_all")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert 0 == count_ship_blocks(html)

      html = fill_board(view1)
      assert 20 == count_ship_blocks(html)
      LiveViewTest.render_click(view2, "ready")
      LiveViewTest.render_click(view1, "drop_all")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert 0 == count_ship_blocks(html)
    end

    test "apply ships, drop last and drop all (opponent)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)
      fill_board(view1)
      html = fill_board(view2, 4)
      assert 12 == count_ship_blocks(html)

      LiveViewTest.render_click(view2, "drop_last")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert 10 == count_ship_blocks(html)

      LiveViewTest.render_click(view1, "ready")
      LiveViewTest.render_click(view2, "drop_last")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert 7 == count_ship_blocks(html)

      LiveViewTest.render_click(view1, "unready")
      LiveViewTest.render_click(view2, "drop_all")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert 0 == count_ship_blocks(html)

      html = fill_board(view2)
      assert 20 == count_ship_blocks(html)
      LiveViewTest.render_click(view1, "ready")
      LiveViewTest.render_click(view2, "drop_all")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert 0 == count_ship_blocks(html)
    end

    test "render new message", %{view1: view, user1: %{name: username}} do
      msg = "game live view test"
      refute LiveViewTest.render(view) =~ msg
      LiveViewTest.render_submit(view, "insert_message", %{"chat-input" => msg})
      :timer.sleep(10)
      assert LiveViewTest.render(view) =~ "#{username}: #{msg}"
    end

    test "render readiness (admin)", %{view1: view} do
      html = fill_board(view)
      assert html =~ "ready"
      LiveViewTest.render_click(view, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view)
      assert html =~ "Ready, await your opponent"
      assert html =~ "unready"
    end

    test "render readiness (opponent)", %{user2: user2, id: id} do
      {:ok, view, :opponent} = mount_view(id, user2)
      html = fill_board(view)
      assert html =~ "ready"
      LiveViewTest.render_click(view, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view)
      assert html =~ "Ready, await your opponent"
      assert html =~ "unready"
    end

    test "start game (ready: admin -> opponent)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)

      html = fill_board(view1)
      assert html =~ "ready"
      LiveViewTest.render_click(view1, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert html =~ "Ready, await your opponent"

      html = fill_board(view2)
      assert html =~ "ready"
      LiveViewTest.render_click(view2, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert html =~ "Make your move" or html =~ "Wait the opponent's move"

      html = LiveViewTest.render(view1)
      assert html =~ "Make your move" or html =~ "Wait the opponent's move"
    end

    test "start game (ready: opponent -> admin)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)

      html = fill_board(view2)
      assert html =~ "ready"
      LiveViewTest.render_click(view2, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert html =~ "Ready, await your opponent"

      html = fill_board(view1)
      assert html =~ "ready"
      LiveViewTest.render_click(view1, "ready")
      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert html =~ "Make your move" or html =~ "Wait the opponent's move"

      html = LiveViewTest.render(view2)
      assert html =~ "Make your move" or html =~ "Wait the opponent's move"
    end

    test "win game (admin)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)
      fill_board(view1)
      fill_board(view2)
      LiveViewTest.render_click(view1, "ready")
      LiveViewTest.render_click(view2, "ready")
      :timer.sleep(10)
      game_server_pid = :sys.get_state(view1.pid).socket.assigns.pid
      game_state = :sys.replace_state(game_server_pid, &%{&1 | turn: &1.admin.id})
      send(game_state.admin_pid, :update_state)
      send(game_state.opponent_pid, :update_state)
      shots = :sys.get_state(view1.pid).socket.assigns.shots

      Enum.reduce(shots, 0, fn
        nil, acc ->
          acc + 1

        _, acc ->
          LiveViewTest.render_click(view1, "shot", "#{acc}")
          acc + 1
      end)

      :timer.sleep(10)
      html = LiveViewTest.render(view1)
      assert html =~ "Congratulations, you win"
      html = LiveViewTest.render(view2)
      assert html =~ "You lose, good luck next time"
    end

    test "win game (opponent)", %{view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(id, user2)
      fill_board(view1)
      fill_board(view2)
      LiveViewTest.render_click(view1, "ready")
      LiveViewTest.render_click(view2, "ready")
      :timer.sleep(10)
      game_server_pid = :sys.get_state(view1.pid).socket.assigns.pid
      game_state = :sys.replace_state(game_server_pid, &%{&1 | turn: &1.opponent.id})
      send(game_state.admin_pid, :update_state)
      send(game_state.opponent_pid, :update_state)
      shots = :sys.get_state(view2.pid).socket.assigns.shots

      Enum.reduce(shots, 0, fn
        nil, acc ->
          acc + 1

        _, acc ->
          LiveViewTest.render_click(view2, "shot", "#{acc}")
          acc + 1
      end)

      :timer.sleep(10)
      html = LiveViewTest.render(view2)
      assert html =~ "Congratulations, you win"
      html = LiveViewTest.render(view1)
      assert html =~ "You lose, good luck next time"
    end

    test "opponent exit on admin exit", %{user1: user1, user2: user2, id: id, conn: conn} do
      {:ok, view2, :opponent} = mount_view(id, user2)

      conn =
        conn
        |> assign(:current_user, user1)
        |> post(session_path(conn, :create), %{
          "session" => %{"username" => user1.username, "password" => "supersecret"}
        })

      delete(conn, game_path(conn, :delete, id))
      assert html_response(conn, 302)
      LiveViewTest.assert_redirect(view2, "/", fn -> :ok end)
    end
  end
end
