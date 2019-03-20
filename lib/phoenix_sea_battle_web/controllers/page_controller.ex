defmodule PhoenixSeaBattleWeb.PageController do
  use PhoenixSeaBattleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
