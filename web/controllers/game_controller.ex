defmodule PhoenixSeaBattle.GameController do
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  use PhoenixSeaBattle.Web, :controller
  plug :authenticate_user

  def index(conn, %{"id" => id}) when is_binary(id) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> conn
              |> put_flash(:error, "Such game not exist")
              |> redirect(to: page_path(conn, :index))
      _pid -> render(conn, "index.html", [id: id])
    end
  end

  def index(conn, _params) do
    <<id::binary-size(8), _rest::binary>> = Ecto.UUID.generate()
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> GameSupervisor.new_game(id)
             redirect(conn, to: "/game/#{id}")
      _ -> index(conn, %{})
    end
  end

  def delete(conn, _params) do
    redirect(conn, page_path(conn, "index.html"))
  end
end