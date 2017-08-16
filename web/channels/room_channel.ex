defmodule PhoenixSeaBattle.RoomChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.Presence

  def join("room:lobby", message, socket) do
    case message["game"] do
      nil -> send self(), :after_join
      gameId -> send self(), {:after_join, gameId}
    end
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    socket = assign(socket, :state, "lobby")
    Presence.track(socket, socket.assigns[:user], %{
      state: "lobby"
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_info({:after_join, gameId}, socket) do
    socket = assign(socket, :state, "game")
    Presence.track(socket, socket.assigns[:user], %{
      state: "game",
      gameId: gameId
    })
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body,
                                    user: socket.assigns[:user],
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end

  intercept ["presence_diff", "new_msg"]

  def handle_out("new_msg", message, socket) do
    if socket.assigns[:state] == "game" do
      {:noreply, socket}
    else
      push socket, "new_msg", message
      {:noreply, socket}
    end
  end

  def handle_out("presence_diff", message, socket) do
    if socket.assigns[:state] == "game" do
      {:noreply, socket}
    else
      push socket, "presence_diff", message
      {:noreply, socket}
    end
  end
end