defmodule PhoenixSeaBattleWeb.GameTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.GameServer
  alias PhoenixSeaBattleWeb.Game, as: GameLive

  @ghost_cell "[\n\s\r]*<div phx-value=\"\\d{1,2}\" class=\"cell ghost_cell\"><\/div>"
  @board_class "class=\"board start_board\" phx-click=\"place\">"
  @empty_cell "[\n\s\r]*<div phx-value=\"\\d{1,2}\" class=\"cell\"><\/div>"
  @vertical_repeatence "#{@ghost_cell}(#{@empty_cell}){9}"

  defp count_ship_cells(html) do
    pattern = :binary.compile_pattern([" ", "\\", "\""])

    html
    |> String.splitter(pattern)
    |> Enum.reduce(0, fn
      x, acc when x in ~w(cross_cell ship_cell) -> acc + 1
      _, acc -> acc
    end)
  end

  defp mount_view(conn, id, user) do
    {:ok, state} = GameServer.add_user(GameSupervisor.via_tuple(id), user)
    token = Phoenix.Controller.get_csrf_token()
    params = [session: %{"user" => user, "id" => id, "token" => token}]
    {:ok, view, _html} = live_isolated(conn, GameLive, params)
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
    html = render(view)
    count = @ships |> Enum.take(ships_count) |> Enum.sum()
    ^count = count_ship_cells(html)
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

    test "add admin, opponent, third player can't connect", %{
      conn: conn,
      user1: user1,
      user2: user2,
      id: id
    } do
      token = Phoenix.Controller.get_csrf_token()

      {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
      {:ok, :admin} = GameServer.add_user(GameSupervisor.via_tuple(id), user1)
      params = [session: %{"user" => user1, "id" => id, "token" => token}]
      {:ok, _view, _html} = live_isolated(conn, GameLive, params)

      {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
      {:ok, :opponent} = GameServer.add_user(GameSupervisor.via_tuple(id), user2)
      params = [session: %{"user" => user2, "id" => id, "token" => token}]
      {:ok, _view, _html} = live_isolated(conn, GameLive, params)

      user3 = insert_user(%{name: "user3"})
      {:error, "game already full"} = GameServer.add_user(GameSupervisor.via_tuple(id), user3)
      params = [session: %{"user" => user3, "id" => id, "token" => token}]
      # User will be redirected to GET /game/:id
      path = "/game/#{id}"
      assert {:error, {:redirect, %{to: ^path}}} = live_isolated(conn, GameLive, params)
    end
  end

  describe "game" do
    setup %{conn: conn} do
      user1 = insert_user(%{name: "user1"})
      user2 = insert_user(%{name: "user2"})
      <<id::binary-8, _::binary>> = Ecto.UUID.generate()
      GameSupervisor.new_game(id)
      {:ok, view1, :admin} = mount_view(conn, id, user1)
      {:ok, %{id: id, user1: user1, user2: user2, view1: view1}}
    end

    test "render board while placing ships", %{view1: view} do
      assert render(view) =~ ~r/#{@board_class}#{@ghost_cell}/

      assert render_hook(view, "mouseover", %{"index" => "10"}) =~
               ~r/#{@board_class}(#{@empty_cell}){10}#{@ghost_cell}/

      assert render_hook(view, "mouseover", %{"index" => "11"}) =~
               ~r/#{@board_class}(#{@empty_cell}){11}#{@ghost_cell}/

      assert render_hook(view, "mouseover", %{"index" => "10"}) =~
               ~r/#{@board_class}(#{@empty_cell}){10}#{@ghost_cell}/

      assert render_hook(view, "mouseover", %{"index" => "0"}) =~
               ~r/#{@board_class}#{@ghost_cell}/

      refute view |> element("#board") |> render_click() =~ "<div class=\"cell ship_cell\">"

      :timer.sleep(10)
      html = render(view)
      assert html =~ ~r/<div phx-value="\d{1,2}" class="cell ship_cell">/
      assert html =~ ~r/(<div phx-value="\d{1,2}" class="cell cross_cell"><\/div>[\n\s]*){3}/
    end

    test "render board while moving ghost (horizontal)", %{view1: view} do
      assert render(view) =~ ~r/class="ghost_ship_horizontal"/
      assert render(view) =~ ~r/#{@board_class}(#{@ghost_cell}*){4}/

      assert render_hook(view, "mouseover", %{"index" => "3"}) =~
               ~r/#{@board_class}(#{@empty_cell}){3}(#{@ghost_cell}*){4}/

      assert render_hook(view, "mouseover", %{"index" => "9"}) =~
               ~r/#{@board_class}(#{@empty_cell}){6}(#{@ghost_cell}*){4}/
    end

    test "render board while moving ghost (vertical)", %{view1: view} do
      view |> element("#rotate") |> render_click() =~ ~r/class="ghost_ship_vertical"/
      assert render(view) =~ ~r/#{@board_class}(#{@vertical_repeatence}){4}#{@empty_cell}/

      assert render_hook(view, "mouseover", %{"index" => "9"}) =~
               ~r/#{@board_class}(#{@empty_cell}){9}(#{@vertical_repeatence}){4}/

      assert render_hook(view, "mouseover", %{"index" => "30"}) =~
               ~r/#{@board_class}(#{@empty_cell}){30}(#{@vertical_repeatence}){4}/

      assert render_hook(view, "mouseover", %{"index" => "90"}) =~
               ~r/#{@board_class}(#{@empty_cell}){60}(#{@vertical_repeatence}){4}/
    end

    test "rotate ghost on board", %{view1: view} do
      h_reg = ~r/#{@board_class}(#{@empty_cell}){66}(#{@ghost_cell}){4}/
      v_reg = ~r/#{@board_class}(#{@empty_cell}){66}(#{@vertical_repeatence}){3}#{@ghost_cell}/

      html = render_hook(view, "mouseover", %{"index" => "99"})

      new_html = view |> element("#rotate") |> render_click()
      refute html == new_html
      assert new_html =~ v_reg

      html = render_hook(view, "mouseover", %{"index" => "99"})

      new_html = view |> element("#rotate") |> render_click()
      refute html == new_html
      assert new_html =~ h_reg

      html = view |> element("#rotate") |> render_click()
      assert html =~ v_reg

      html = view |> element("#rotate") |> render_click()
      assert html =~ h_reg
    end

    test "render error messages (admin)", %{view1: view} do
      assert render(view) =~ "Place your ships"
      view |> element("#board") |> render_click()
      view |> element("#board") |> render_click()
      :timer.sleep(10)
      assert render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t cross"
      render_hook(view, "mouseover", %{"index" => "10"})
      view |> element("#board") |> render_click()
      :timer.sleep(10)
      assert render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t touch"
      :timer.sleep(100)
      refute render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t touch"
    end

    test "render error messages (opponent)", %{conn: conn, user2: user, id: id} do
      {:ok, view, :opponent} = mount_view(conn, id, user)

      assert render(view) =~ "Place your ships"
      view |> element("#board") |> render_click()
      view |> element("#board") |> render_click()
      :timer.sleep(10)
      assert render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t cross"
      render_hook(view, "mouseover", %{"index" => "10"})
      view |> element("#board") |> render_click()
      :timer.sleep(10)
      assert render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t touch"
      :timer.sleep(100)
      refute render(view) =~ "<div class=\"error\">\nShips shouldn&#39;t touch"
    end

    test "render opponent status", %{conn: conn, view1: view1, id: id, user2: user2} do
      assert render(view1) =~ "No opponent"
      {:ok, _, :opponent} = mount_view(conn, id, user2)
      :timer.sleep(10)
      assert render(view1) =~ "Opponent: #{user2.name}"
    end

    # TODO check and fix
    test "apply ships, drop last and drop all (admin)", %{
      conn: conn,
      view1: view1,
      user2: user2,
      id: id
    } do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)
      fill_board(view2)
      html = fill_board(view1, 4)
      assert 12 == count_ship_cells(html)

      render_click(view1, "drop_last")
      :timer.sleep(10)
      html = render(view1)
      assert 10 == count_ship_cells(html)

      render_click(view2, "ready")
      render_click(view1, "drop_last")
      :timer.sleep(10)
      html = render(view1)
      assert 7 == count_ship_cells(html)

      render_click(view2, "unready")
      render_click(view1, "drop_all")
      :timer.sleep(10)
      html = render(view1)
      assert 0 == count_ship_cells(html)

      html = fill_board(view1)
      assert 20 == count_ship_cells(html)
      render_click(view2, "ready")
      render_click(view1, "drop_all")
      :timer.sleep(10)
      html = render(view1)
      assert 0 == count_ship_cells(html)
    end

    test "apply ships, drop last and drop all (opponent)", %{
      conn: conn,
      view1: view1,
      user2: user2,
      id: id
    } do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)
      fill_board(view1)
      html = fill_board(view2, 4)
      assert 12 == count_ship_cells(html)

      render_click(view2, "drop_last")
      :timer.sleep(10)
      html = render(view2)
      assert 10 == count_ship_cells(html)

      render_click(view1, "ready")
      render_click(view2, "drop_last")
      :timer.sleep(10)
      html = render(view2)
      assert 7 == count_ship_cells(html)

      render_click(view1, "unready")
      render_click(view2, "drop_all")
      :timer.sleep(10)
      html = render(view2)
      assert 0 == count_ship_cells(html)

      html = fill_board(view2)
      assert 20 == count_ship_cells(html)
      render_click(view1, "ready")
      render_click(view2, "drop_all")
      :timer.sleep(10)
      html = render(view2)
      assert 0 == count_ship_cells(html)
    end

    test "render new message", %{view1: view, user1: %{name: username}} do
      msg = "game live view test"
      refute render(view) =~ msg
      render_submit(view, "insert_message", %{"chat-input" => msg})
      :timer.sleep(10)
      assert render(view) =~ "#{username}: #{msg}"
    end

    test "render readiness (admin)", %{view1: view} do
      html = fill_board(view)
      assert html =~ "ready"
      render_click(view, "ready")
      :timer.sleep(10)
      html = render(view)
      assert html =~ "Ready, await your opponent"
      assert html =~ "unready"
    end

    test "render readiness (opponent)", %{conn: conn, user2: user2, id: id} do
      {:ok, view, :opponent} = mount_view(conn, id, user2)
      html = fill_board(view)
      assert html =~ "ready"
      render_click(view, "ready")
      :timer.sleep(10)
      html = render(view)
      assert html =~ "Ready, await your opponent"
      assert html =~ "unready"
    end

    test "start game (ready: admin -> opponent)", %{
      conn: conn,
      view1: view1,
      user2: user2,
      id: id
    } do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)

      html = fill_board(view1)
      assert html =~ "ready"
      render_click(view1, "ready")
      :timer.sleep(10)
      html = render(view1)
      assert html =~ "Ready, await your opponent"

      html = fill_board(view2)
      assert html =~ "ready"
      render_click(view2, "ready")
      :timer.sleep(10)
      html = render(view2)
      assert html =~ "Make your move" or html =~ "Wait the opponent&#39;s move"

      html = render(view1)
      assert html =~ "Make your move" or html =~ "Wait the opponent&#39;s move"
    end

    test "start game (ready: opponent -> admin)", %{
      conn: conn,
      view1: view1,
      user2: user2,
      id: id
    } do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)

      html = fill_board(view2)
      assert html =~ "ready"
      render_click(view2, "ready")
      :timer.sleep(10)
      html = render(view2)
      assert html =~ "Ready, await your opponent"

      html = fill_board(view1)
      assert html =~ "ready"
      render_click(view1, "ready")
      :timer.sleep(10)
      html = render(view1)
      assert html =~ "Make your move" or html =~ "Wait the opponent&#39;s move"

      html = render(view2)
      assert html =~ "Make your move" or html =~ "Wait the opponent&#39;s move"
    end

    test "win game (admin)", %{conn: conn, view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)
      fill_board(view1)
      fill_board(view2)
      render_click(view1, "ready")
      render_click(view2, "ready")
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
          render_click(view1, "shot", %{"index" => "#{acc}"})
          acc + 1
      end)

      :timer.sleep(10)
      html = render(view1)
      assert html =~ "Congratulations, you win"
      html = render(view2)
      assert html =~ "You lose, good luck next time"
    end

    test "win game (opponent)", %{conn: conn, view1: view1, user2: user2, id: id} do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)
      fill_board(view1)
      fill_board(view2)
      render_click(view1, "ready")
      render_click(view2, "ready")
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
          render_click(view2, "shot", %{"index" => "#{acc}"})
          acc + 1
      end)

      :timer.sleep(10)
      html = render(view2)
      assert html =~ "Congratulations, you win"
      html = render(view1)
      assert html =~ "You lose, good luck next time"
    end

    test "opponent exit on admin exit", %{user1: user1, user2: user2, id: id, conn: conn} do
      {:ok, view2, :opponent} = mount_view(conn, id, user2)

      conn =
        conn
        |> assign(:current_user, user1)
        |> post(session_path(conn, :create), %{
          "session" => %{"username" => user1.username, "password" => "supersecret"}
        })

      delete(conn, game_path(conn, :delete, id))
      assert html_response(conn, 302)
      assert_redirect(view2, "/")
    end
  end
end
