defmodule PhoenixSeaBattleWeb.PageController do
  use PhoenixSeaBattleWeb, :controller

  def index(conn, _params) do
    # Phoenix.LiveView.Controller.live_render(conn, PhoenixSeaBattleWeb.Live.Lobby, session: %{"user" => get_session(conn, :current_user)})
    render(conn, "index.html")
  end
end
