defmodule PhoenixSeaBattle.SessionControllerTest do
  use PhoenixSeaBattle.ConnCase
  require Logger

  setup %{conn: conn} = config do
    conn =
      conn
      |> bypass_through(PhoenixSeaBattle.Router, :browser)
      |> get("/")
    if username = config[:exist_user] do
      user = insert_user(%{username: username, password: "secret"})
      {:ok, %{conn: conn, user: user}}
    else
      {:ok, %{conn: conn}}
    end
  end

  test "GET /sessions/new", %{conn: conn} do
    conn = get conn, "sessions/new"
    assert html_response(conn, 200)
  end

  @tag exist_user: "max123"
  test "DELETE sessions/:id", %{conn: conn, user: user} do
    conn = conn |> post(session_path(conn, :create), %{"session" => %{"username" => Map.get(user, :username), "password" => "secret"}})
                |> delete("sessions/#{inspect Map.get(user, :id)}")
    assert html_response(conn, 302)
  end

  @tag exist_user: "max123"
  test "POST sessions invalid", %{conn: conn, user: user} do
    conn = post conn, "sessions", %{"session" => %{"username" => Map.get(user, :username), "password" => "123"}}
    assert html_response(conn, 200) =~ "Invalid username/password combination"
  end
end