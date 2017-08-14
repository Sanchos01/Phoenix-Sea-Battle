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
    case socket.assigns[:user_id] do
      nil -> push socket, "presence_state", Presence.list(socket)
             {:noreply, socket}
      user_id ->  username = Repo.get(PhoenixSeaBattle.User, user_id).username
                  Logger.debug("#{inspect username}")
                  Presence.track(socket, username, %{
                    online_at: System.system_time(:milliseconds),
                    state: "lobby"
                  })
                  broadcast! socket, "user_joined", %{user: username,
                                                      timestamp: System.system_time(:milliseconds)}
                  push socket, "presence_state", Presence.list(socket)
                  {:noreply, socket}
    end
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    Logger.debug("new_msg on socket: #{inspect body}; #{inspect socket}")
    username = case socket.assigns[:user_id] do
      nil -> <<uid::bytes-size(8), _::binary>> = socket.assigns[:anonymous]
             "Anon:" <> uid
      user_id -> Repo.get(PhoenixSeaBattle.User, user_id).username
    end
    broadcast! socket, "new_msg", %{body: body,
                                    user: username,
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end
end