defmodule PhoenixSeaBattleWeb.Router do
  use PhoenixSeaBattleWeb, :router
  alias Phoenix.Token

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PhoenixSeaBattleWeb.Auth, repo: PhoenixSeaBattle.Repo
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixSeaBattleWeb do
    pipe_through :browser # Use the default browser stack
    resources "/users",    UserController,    only: ~w(index show new create)a
    resources "/sessions", SessionController, only: ~w(new create delete)a
    resources "/game",     GameController,    only: ~w(index delete show)a

    get "/", PageController, :index
  end

  defp put_user_token(conn = %{assigns: %{current_user: %{id: id}}}, _) do
    token = Token.sign(conn, "user socket", id)
    assign(conn, :user_token, token)
  end
  defp put_user_token(conn, _), do: conn

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixSeaBattle do
  #   pipe_through :api
  # end
end
