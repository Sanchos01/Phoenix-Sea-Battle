defmodule PhoenixSeaBattle.RoomChannel do
  require Logger
  use PhoenixSeaBattle.Web, :channel
  alias PhoenixSeaBattle.{Presence, Game}
  import PhoenixSeaBattle.Game.Supervisor, only: [via_tuple: 1]

  # states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def join("room:lobby", message, socket) do
    case message["game"] do
      nil -> send self(), :after_join
      gameId -> send self(), {:after_join, gameId}
    end
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    socket = assign(socket, :state, 0)
    Presence.track(socket, socket.assigns[:user], %{
      state: 0
    })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end

  def handle_info({:after_join, gameId}, socket) do
    pid = GenServer.whereis(via_tuple(gameId))
    {:ok, [gamestate: %Game{admin: admin, opponent: opponent}]} = Game.get(pid)
    meta = cond do
      admin && opponent -> %{state: 2, with: (admin || opponent)}
      true -> %{state: 1, gameId: gameId}
    end
    socket = assign(socket, :state, 1)
    Presence.track(socket, socket.assigns[:user], meta)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast! socket, "new_msg", %{body: body,
                                    user: socket.assigns[:user],
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end

  intercept ["presence_diff", "new_msg", "change_state"]

  def handle_out("new_msg", message, socket) do
    if socket.assigns[:state] != 0 do
      {:noreply, socket}
    else
      push socket, "new_msg", message
      {:noreply, socket}
    end
  end

  def handle_out("presence_diff", message, socket) do
    if socket.assigns[:state] != 0 do
      {:noreply, socket}
    else
      push socket, "presence_diff", message
      {:noreply, socket}
    end
  end

  def handle_out("change_state", %{"users" => users}, socket) do
    Enum.map(users, fn {user, meta} ->
      Presence.update(socket, user, meta)
    end)
    {:noreply, socket}
  end
end