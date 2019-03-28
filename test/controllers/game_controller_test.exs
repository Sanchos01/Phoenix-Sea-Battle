defmodule PhoenixSeaBattle.GameControllerTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  import Mock

  setup %{conn: conn} = config do
    <<id::binary-8, _::binary>> = Ecto.UUID.generate()
    GameSupervisor.new_game(id)
    user_max123 = insert_user(%{name: "max123", username: "user_max123", password: "secret"})
    user_alex123 = insert_user(%{name: "alex123", username: "user_alex123", password: "secret"})
    {:ok, :admin} = Game.add_user(GameSupervisor.via_tuple(id), user_max123)
    {:ok, :opponent} = Game.add_user(GameSupervisor.via_tuple(id), user_alex123)

    config = case config[:login_as] do
      "max123" ->
        conn =
          conn
          |> assign(:current_user, user_max123)
          |> post(session_path(conn, :create), %{
            "session" => %{"username" => user_max123.username, "password" => "secret"}
          })

        Map.merge config, %{conn: conn, user_max123: user_max123, user_alex123: user_alex123, id: id}

      "alex123" ->
        conn =
          conn
          |> assign(:current_user, user_alex123)
          |> post(session_path(conn, :create), %{
            "session" => %{"username" => user_alex123.username, "password" => "secret"}
          })

        Map.merge config, %{conn: conn, user_max123: user_max123, user_alex123: user_alex123, id: id}

      "" <> name ->
        user = insert_user(%{name: name, username: "user_#{name}", password: "secret"})
        conn =
          conn
          |> assign(:current_user, user_alex123)
          |> post(session_path(conn, :create), %{
            "session" => %{"username" => user.username, "password" => "secret"}
          })

        Map.merge config, %{conn: conn, user_max123: user_max123, user_alex123: user_alex123, id: id, user: user}
      
      _ ->
        Map.merge config, %{conn: conn, user_max123: user_max123, user_alex123: user_alex123, id: id}
    end

    if id = config[:game_id] do
      GameSupervisor.new_game(id)
    end

    {:ok, config}
  end

  @tag login_as: "max123"
  test "GET /game", %{conn: conn} do
    conn = get(conn, game_path(conn, :index))
    assert html_response(conn, 302)
  end

  @tag login_as: "max123"
  test "GET /game/:id (exist game, admin)", %{conn: conn, id: id} do
    conn = get(conn, game_path(conn, :show, id))
    assert html_response(conn, 200)
  end

  @tag login_as: "alex123"
  test "GET /game/:id (exist game, opponent)", %{conn: conn, id: id} do
    conn = get(conn, game_path(conn, :show, id))
    assert html_response(conn, 200)
  end

  @tag login_as: "john123"
  test "GET /game/:id (exist game, wrong user)", %{conn: conn, id: id} do
    conn = get(conn, game_path(conn, :show, id))
    assert html_response(conn, 302)
  end

  @tag login_as: "max123"
  test "GET /game/:id (game not exist)", %{conn: conn} do
    <<id::binary-8, _::binary>> = Ecto.UUID.generate()
    conn = get(conn, game_path(conn, :show, id))
    assert html_response(conn, 302)
  end

  @tag login_as: "max123"
  test "DELETE sessions/:id", %{conn: conn, id: game_id} do
    pid = "#{game_id}" |> GameSupervisor.via_tuple() |> GenServer.whereis()
    ref = Process.monitor(pid)
    conn = delete(conn, game_path(conn, :delete, game_id))
    assert html_response(conn, 302)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 100
  end

  @tag login_as: "john123", game_id: "17342072"
  test "GET /game (generated exist game_id)", %{conn: conn} do
    # next :rand.uniform(10_000_000) == 7_342_072
    :rand.seed(:exs64, {1, 1, 1})

    with_mock Ecto.UUID,
      generate: fn -> Integer.to_string(:rand.uniform(10_000_000) + 10_000_000) end do
      conn = get(conn, game_path(conn, :index))
      assert html_response(conn, 302)
    end
  end
end
