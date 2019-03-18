defmodule PhoenixSeaBattleWeb.GameController do
  require Logger
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  alias Ecto.UUID
  use PhoenixSeaBattleWeb, :controller
  plug :authenticate_user

  def show(conn = %{assigns: %{current_user: %{username: username}}}, %{"id" => id}) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil ->
        conn
        |> put_flash(:error, "Such game not exist")
        |> redirect(to: page_path(conn, :index))
      pid ->
        case Game.add_user(pid, username) do
          {:ok, status} when status in ~w(admin opponent)a ->
            render(conn, "index.html", id: id, admin: status == :admin)
          {:error, reason} ->
            conn
            |> put_flash(:error, reason)
            |> redirect(to: page_path(conn, :index))
        end
    end
  end

  def index(conn, _params) do
    <<id::binary-size(8), _rest::binary>> = UUID.generate()
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil ->
        GameSupervisor.new_game(id)
        redirect(conn, to: game_path(conn, :show, id))
      _ ->
        index(conn, nil)
    end
  end

  def delete(conn = %{assigns: %{current_user: %{username: user}}}, %{"id" => id}) do
    case GenServer.whereis(GameSupervisor.via_tuple(id)) do
      nil -> :ok
      pid -> send(pid, {:terminate, user})
    end
    redirect(conn, to: page_path(conn, :index))
  end
end
