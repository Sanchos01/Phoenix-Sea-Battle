defmodule PhoenixSeaBattle.GameChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.Presence

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
    Presence.track(socket, socket.assigns[:user], %{
    })
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body,
                                    user: socket.assigns[:user]}
    {:noreply, socket}
  end
end
