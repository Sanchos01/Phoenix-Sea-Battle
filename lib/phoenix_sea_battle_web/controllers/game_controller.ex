defmodule PhoenixSeaBattleWeb.GameController do
  require Logger
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.GameServer
  alias Ecto.UUID
  use PhoenixSeaBattleWeb, :controller
  plug(:authenticate_user)

  def show(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil ->
        conn
        |> put_flash(:error, "Such game not exist")
        |> redirect(to: Routes.page_path(conn, :index))

      pid ->
        case GameServer.add_user(pid, user) do
          {:ok, status} when status in ~w(admin opponent)a ->
            render(conn, "index.html", id: id, token: Phoenix.Controller.get_csrf_token())

          {:error, reason} ->
            conn
            |> put_flash(:error, reason)
            |> redirect(to: Routes.page_path(conn, :index))
        end
    end
  end

  def index(conn, _params) do
    <<id::binary-size(8), _rest::binary>> = UUID.generate()

    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil ->
        GameSupervisor.new_game(id)
        redirect(conn, to: Routes.game_path(conn, :show, id))

      _ ->
        index(conn, nil)
    end
  end

  def delete(conn = %{assigns: %{current_user: user}}, %{"id" => id}) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> :ok
      pid -> send(pid, {:terminate, user})
    end

    redirect(conn, to: Routes.page_path(conn, :index))
  end
end
