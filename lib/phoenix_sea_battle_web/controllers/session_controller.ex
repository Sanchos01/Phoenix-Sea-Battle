defmodule PhoenixSeaBattleWeb.SessionController do
  alias PhoenixSeaBattleWeb.Auth
  use PhoenixSeaBattleWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"username" => user, "password" => pass}}) do
    case Auth.login_by_username_and_pass(conn, user, pass) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back, #{user}!")
        |> redirect(to: page_path(conn, :index))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end
end
