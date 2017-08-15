defmodule PhoenixSeaBattle.GameChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.Repo
  alias PhoenixSeaBattle.Presence

  def join("game:" <> id, _message, socket) do
    send self(), :after_join
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
    Presence.track(socket, username, %{
      state: "game"
    })
    Logger.debug("#{inspect socket}")
    {:noreply, socket}
  end
  
    def handle_in("new_msg", %{"body" => body}, socket) do
      username = Repo.get(PhoenixSeaBattle.User, socket.assigns[:user_id]).username
      broadcast! socket, "new_msg", %{body: body,
                                      user: username}
      {:noreply, socket}
    end
end
