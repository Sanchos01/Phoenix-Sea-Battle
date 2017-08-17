defmodule PhoenixSeaBattle.GameController do
  require Logger
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  use PhoenixSeaBattle.Web, :controller
  plug :authenticate_user

  def index(conn, %{"id" => id}) when is_binary(id) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> conn
              |> put_flash(:error, "Such game not exist")
              |> redirect(to: page_path(conn, :index))
      pid -> username = conn.assigns[:current_user].username
             case PhoenixSeaBattle.Game.add_user(pid, username) do
               :ok -> render(conn, "index.html", [id: id])
               {:error, reason} -> conn
                                   |> put_flash(:error, reason)
                                   |> redirect(to: page_path(conn, :index))
             end
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

  def delete(conn, %{"id" => id}) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> :ok
      pid -> send(pid, :terminate)
    end
    conn
      |> redirect(to: page_path(conn, :index))
  end
end