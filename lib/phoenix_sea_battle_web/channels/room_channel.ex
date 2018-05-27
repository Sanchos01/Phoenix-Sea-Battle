defmodule PhoenixSeaBattleWeb.RoomChannel do
  require Logger
  use PhoenixSeaBattleWeb, :channel
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.{Game, LobbyArchiver}
  import PhoenixSeaBattle.Game.Supervisor, only: [via_tuple: 1]

  # states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def join("room:lobby", message, socket) do
    case message["game"] do
      nil -> send self(), {:after_join, ts: (message["last_seen_ts"] || 0)}
      gameId -> send self(), {:after_join, gameId}
    end
    {:ok, socket}
  end

  def handle_info({:after_join, ts: ts}, socket = %{assigns: %{user: user}}) do
    socket = assign(socket, :state, 0)
    Presence.track(socket, user, %{state: 0})
    push socket, "presence_state", Presence.list(socket)
    pre_messages = LobbyArchiver.get_messages(ts)
    push socket, "pre_messages", %{"body" => pre_messages}
    {:noreply, socket}
  end

  def handle_info({:after_join, gameId}, socket = %{assigns: %{user: user}}) do
    case GenServer.whereis(via_tuple(gameId)) do
      nil ->
        socket = assign(socket, :state, 3)
        Presence.track(socket, user, %{state: 3})
        {:noreply, socket}
      pid ->
        {:ok, %Game{admin: admin, opponent: opponent}} = Game.get(pid)
        {meta, state} = cond do
          admin && opponent -> if user == admin, do: {%{state: 2, with: opponent}, 2}, else: {%{state: 2, with: admin}, 2}
          true -> {%{state: 1, gameId: gameId}, 1}
        end
        socket = assign(socket, :state, state)
        Presence.track(socket, user, meta)
        {:noreply, socket}
    end
  end

  def handle_in("new_msg", %{"body" => body}, socket = %{assigns: %{user: user}}) do
    broadcast! socket, "new_msg", %{body: body,
                                    user: user,
                                    timestamp: System.system_time(:milliseconds)}
    {:noreply, socket}
  end

  intercept ["presence_diff", "new_msg", "change_state"]

  def handle_out(cmd, message, socket = %{assigns: %{state: 0}}) when cmd in ~w(new_msg presence_diff) do
    push socket, cmd, message
    {:noreply, socket}
  end
  def handle_out(cmd, _message, socket) when cmd in ~w(new_msg presence_diff), do: {:noreply, socket}

  def handle_out("change_state", %{"users" => users}, socket = %{assigns: %{user: user}}) do
    if meta = Map.get(users, user) do
      Presence.update(socket, user, meta)
    end
    {:noreply, socket}
  end
end