defmodule PhoenixSeaBattle.RoomChannel do
  require Logger
  use Phoenix.Channel
  alias PhoenixSeaBattle.Repo

  def join("room:lobby", _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end
  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    case socket.assigns[:user_id] do
      nil -> {:noreply, socket}
      user_id -> username = Repo.get(PhoenixSeaBattle.User, user_id).username
                 broadcast! socket, "join_user", %{user: username}
                 {:noreply, socket}
    end
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    Logger.debug("new_msg on socket: #{inspect body}; #{inspect socket}")
    username = case socket.assigns[:user_id] do
      nil -> <<uuid::bytes-size(6), _::binary>> = socket.assigns[:anonymous]
             "Anon:" <> uuid
      user_id -> Repo.get(PhoenixSeaBattle.User, user_id).username
    end
    broadcast! socket, "new_msg", %{body: body, user: username}
    {:noreply, socket}
  end
end