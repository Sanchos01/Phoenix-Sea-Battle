defmodule PhoenixSeaBattleWeb.GameChannel do
  require Logger
  use PhoenixSeaBattleWeb, :channel
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.Game
  import PhoenixSeaBattle.Game.Supervisor, only: [via_tuple: 1]

  def join("game:" <> id, _message, socket) do
    list_users = socket |> Presence.list() |> Map.keys()

    if length(list_users) == 2 do
      {:error, "this room is full"}
    else
      send(self(), :after_join)
      {:ok, assign(socket, :game_id, id)}
    end
  end

  def handle_info(:after_join, socket = %{assigns: %{user: user}}) do
    Presence.track(socket, user, %{})
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket = %{assigns: %{user: user}}) do
    broadcast!(socket, "new_msg", %{body: body, user: user})
    {:noreply, socket}
  end

  def handle_in("get_state", %{}, socket = %{assigns: %{game_id: game_id}}) do
    msg = %{state: state} = Game.get_state(via_tuple(game_id))
    push(socket, "get_state", %{"state" => state, "body" => msg[:body]})
    {:noreply, socket}
  end

  def handle_in("ready", %{"body" => body}, socket = %{assigns: %{user: user, game_id: game_id}}) do
    case Game.readiness(via_tuple(game_id), user, body) do
      :ok ->
        push(socket, "board_ok", %{})

      :start ->
        broadcast!(socket, "start_game", %{})

      some ->
        Logger.error("something wrong with ships position: #{inspect(some)}")
        push(socket, "bad_position", %{})
    end

    {:noreply, socket}
  end
end
