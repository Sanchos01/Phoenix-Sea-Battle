defmodule PhoenixSeaBattle.Router do
  use PhoenixSeaBattle.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PhoenixSeaBattle.Auth, repo: PhoenixSeaBattle.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixSeaBattle do
    pipe_through :browser # Use the default browser stack
    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]

    get "/", PageController, :index
  end
  
  # Other scopes may use custom stacks.
  # scope "/api", PhoenixSeaBattle do
  #   pipe_through :api
  # end
end
