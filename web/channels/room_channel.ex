defmodule PhoenixSeaBattle.RoomChannel do
  require Logger
  use Phoenix.Channel
  alias PhoenixSeaBattle.Repo
  alias PhoenixSeaBattle.Presence

  def join("room:lobby", _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    Presence.track(socket, username, %{
      online_at: System.system_time(:milliseconds),
      state: "lobby"
    })
    broadcast! socket, "user_joined", %{user: username,
                                        timestamp: System.system_time(:milliseconds)}
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    Logger.debug("new_msg on socket: #{inspect body}; #{inspect socket}")
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    broadcast! socket, "new_msg", %{body: body,
                                    user: username,
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end
end