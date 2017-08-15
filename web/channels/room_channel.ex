defmodule PhoenixSeaBattle.RoomChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.Repo
  alias PhoenixSeaBattle.Presence

  def join("room:lobby", _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    Presence.track(socket, username, %{
      state: "lobby"
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    broadcast! socket, "new_msg", %{body: body,
                                    user: username,
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end
end