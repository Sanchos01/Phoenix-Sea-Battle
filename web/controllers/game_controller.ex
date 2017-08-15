defmodule PhoenixSeaBattle.GameController do
  use PhoenixSeaBattle.Web, :controller
  plug :authenticate_user
  alias PhoenixSeaBattle.User

  def index(conn, %{"id" => id}) do
    render conn, "index.html", [
      id: id
    ]
  end

    def index(conn, _params) do
      <<id::binary-size(8), _rest::binary>> = Ecto.UUID.generate()
      redirect(conn, to: "/game/#{id}")
    end

  def delete(conn, _params) do
    redirect(conn, page_path(conn, "index.html"))
  end
end