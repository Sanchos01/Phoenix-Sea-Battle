defmodule PhoenixSeaBattle.GameChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.Presence

  def join("game:" <> _id, _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns[:user], %{
      state: "game"
    })
    {:noreply, socket}
  end
  
    def handle_in("new_msg", %{"body" => body}, socket) do
      broadcast! socket, "new_msg", %{body: body,
                                      user: socket.assigns[:user]}
      {:noreply, socket}
    end
end
