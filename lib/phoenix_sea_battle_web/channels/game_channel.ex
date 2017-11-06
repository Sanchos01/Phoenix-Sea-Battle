defmodule PhoenixSeaBattleWeb.GameChannel do
  require Logger
  use PhoenixSeaBattleWeb, :channel
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.Game
  import PhoenixSeaBattle.Game.Supervisor, only: [via_tuple: 1]

  def join("game:" <> id, _message, socket) do
    list_users = Presence.list(socket) |> Map.keys()
    cond do
      length(list_users) > 1 ->
        {:error, "this room is full"}
      true ->
        send self(), :after_join
        {:ok, assign(socket, :game_id, id)}
    end
  end

  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns[:user], %{})
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body,
                                    user: socket.assigns[:user]}
    {:noreply, socket}
  end

  def handle_in("get_state", %{}, socket) do
    msg = Game.get_state(via_tuple(socket.assigns[:game_id]), socket.assigns[:user])
    push socket, "get_state", %{"state" => msg.state, "body" => msg[:body]}
    {:noreply, socket}
  end

  def handle_in("ready", %{"body" => body}, socket) do
    case Game.readiness(via_tuple(socket.assigns[:game_id]), socket.assigns[:user], body) do
      :ok -> push socket, "board_ok", %{}
      :start -> broadcast! socket, "start_game", %{}
      some -> Logger.error("something wrong with ships position: #{inspect some}")
              push socket, "bad_position", %{}
    end
    {:noreply, socket}
  end
end
