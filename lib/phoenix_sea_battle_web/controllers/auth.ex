defmodule PhoenixSeaBattleWeb.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller
  alias PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattle.User

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = init(opts)
    user = repo.get_by(User, username: username)

    cond do
      user ->
        cond do
          !is_nil(user.password_hash) && checkpw(given_pass, user.password_hash) ->
            {:ok, login(conn, user)}
          true -> {:error, :unauthorized, conn}
        end
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def init(opts), do: Keyword.fetch!(opts, :repo)

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    user = user_id && repo.get(User, user_id)
    assign(conn, :current_user, user)
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end
end