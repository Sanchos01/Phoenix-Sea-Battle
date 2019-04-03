defmodule PhoenixSeaBattleWeb.UserController do
  use PhoenixSeaBattleWeb, :controller

  alias PhoenixSeaBattle.User
  alias PhoenixSeaBattleWeb.UserLive
  alias Phoenix.LiveView.Controller, as: LiveController

  plug(:authenticate_user when action in [:index, :show])

  def index(conn, _params) do
    LiveController.live_render(conn, UserLive.Index, session: %{})
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    render(conn, "show.html", user: user)
  end

  def new(conn, _params) do
    LiveController.live_render(conn, UserLive.New, session: %{})
  end
end
