defmodule PhoenixSeaBattle.RoomChannel do
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
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    broadcast! socket, "join_user", %{user: username}
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    broadcast! socket, "new_msg", %{body: body, user: username}
    {:noreply, socket}
  end
end