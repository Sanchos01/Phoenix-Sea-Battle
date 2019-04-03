defmodule PhoenixSeaBattle.UserControllerTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true

  setup %{conn: conn} = config do
    if username = config[:login_as] do
      user = insert_user(%{username: username, password: "secret"})

      conn =
        conn
        |> assign(:current_user, user)
        |> post(session_path(conn, :create), %{
          "session" => %{"username" => username, "password" => "secret"}
        })

      {:ok, %{conn: conn, user: user}}
    else
      :ok
    end
  end

  @tag login_as: "max123"
  test "GOT /users", %{conn: conn} do
    conn = get(conn, "/users")
    assert html_response(conn, 200) =~ "max123"
  end

  @tag login_as: "max123"
  test "GOT /users/:id", %{conn: conn} do
    id = conn.assigns[:current_user] |> Map.get(:id)
    conn = get(conn, "/users/#{id}")
    assert html_response(conn, 200) =~ "max123"
  end

  test "GOT /users/new", %{conn: conn} do
    conn = get(conn, "/users/new")
    assert html_response(conn, 200)
  end
end
