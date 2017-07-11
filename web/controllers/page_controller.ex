defmodule PhoenixSeaBattle.PageController do
  use PhoenixSeaBattle.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
