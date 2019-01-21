defmodule PhoenixSeaBattle.GameControllerTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  import Mock
  @valid_game "11111111"
  @invalid_game "22222222"

  setup_all do
    GameSupervisor.new_game(@valid_game)
    {:ok, :admin} = Game.add_user(GameSupervisor.via_tuple(@valid_game), "max123")
    {:ok, :opponent} = Game.add_user(GameSupervisor.via_tuple(@valid_game), "alex123")
    :ok
  end

  setup %{conn: conn} = config do
    if username = config[:login_as] do
      user = insert_user(%{username: username, password: "secret"})
      conn = conn
        |> assign(:current_user, user)
        |> post(session_path(conn, :create), %{"session" => %{"username" => username, "password" => "secret"}})
      if game_id = config[:game_id] do
        GameSupervisor.new_game(game_id)
        {:ok, :admin} = Game.add_user(GameSupervisor.via_tuple(game_id), username)
        {:ok, %{conn: conn, game_id: game_id}}
      end
      {:ok, %{conn: conn}}
    else
      :ok
    end
  end

  @tag login_as: "max123"
  test "GOT /game", %{conn: conn} do
    conn = get conn, "/game"
    assert html_response(conn, 302)
  end

  @tag login_as: "max123"
  test "GOT /game/#{@valid_game} (exist game, admin)", %{conn: conn} do
    conn = get conn, "/game/#{@valid_game}"
    assert html_response(conn, 200)
  end

  @tag login_as: "alex123"
  test "GOT /game/#{@valid_game} (exist game, opponent)", %{conn: conn} do
    conn = get conn, "/game/#{@valid_game}"
    assert html_response(conn, 200)
  end

  @tag login_as: "john123"
  test "GOT /game/#{@valid_game} (exist game, wrong user)", %{conn: conn} do
    conn = get conn, "/game/#{@valid_game}"
    assert html_response(conn, 302)
  end
  
  @tag login_as: "max123"
  test "GOT /game/#{@invalid_game} (game not exist)", %{conn: conn} do
    conn = get conn, "/game/#{@invalid_game}"
    assert html_response(conn, 302)
  end

  @tag login_as: "alex123", game_id: "11223344"
  test "DELETE sessions/:id", %{conn: conn, game_id: game_id} do
    pid = "#{game_id}" |> GameSupervisor.via_tuple() |> GenServer.whereis()
    ref = Process.monitor(pid)
    conn = conn |> delete("game/#{game_id}")
    assert html_response(conn, 302)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 100
  end

  @tag login_as: "john123"
  test "Got /game (generated exist game_id)", %{conn: conn} do
    GameSupervisor.new_game("17342072")
    :rand.seed(:exs64, {1, 1, 1}) # next :rand.uniform(10_000_000) == 7_342_072
    with_mock Ecto.UUID, [
        generate: fn() -> Integer.to_string(:rand.uniform(10_000_000) + 10_000_000) end
      ] do

      conn = get conn, "/game"
      assert html_response(conn, 302)
    end
  end
end
