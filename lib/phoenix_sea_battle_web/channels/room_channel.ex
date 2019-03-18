defmodule PhoenixSeaBattleWeb.RoomChannel do
  @moduledoc false
  use PhoenixSeaBattleWeb, :channel
  require Logger
  import PhoenixSeaBattle.Game.Supervisor, only: [via_tuple: 1]
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.Game

  # states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def join("room:lobby", message, socket) do
    case message["game"] do
      # nil     ->
      #   ts = message["last_seen_ts"] || 0
      #   send self(), {:after_join, ts: ts}
      game_id ->
        send self(), {:after_join, game_id: game_id}
    end
    {:ok, socket}
  end

  # def handle_info({:after_join, ts: ts}, socket = %{assigns: %{user: user}}) do
  #   socket = assign(socket, :state, 0)
  #   Presence.track(socket, user, %{state: 0})
  #   pre_messages = LobbyArchiver.get_messages(ts)
  #   push socket, "pre_messages", %{"body" => pre_messages}
  #   {:noreply, socket}
  # end

  def handle_info({:after_join, game_id: game_id}, socket = %{assigns: %{user: user}}) do
    case GenServer.whereis(via_tuple(game_id)) do
      nil ->
        socket = assign(socket, :state, 3)
        Presence.track(socket, user, %{state: 3})
        {:noreply, socket}
      pid ->
        {:ok, %Game{admin: admin, opponent: opponent}} = Game.get(pid)
        state = get_state(user, admin, opponent)
        socket = assign(socket, :state, state)
        Presence.track(socket, user, %{state: state, game_id: game_id})
        {:noreply, socket}
    end
  end

  # def handle_in("new_msg", %{"body" => body}, socket = %{assigns: %{user: user}}) do
  #   msg = %{body: body, user: user, timestamp: System.system_time(:millisecond)}
  #   broadcast! socket, "new_msg", msg
  #   {:noreply, socket}
  # end

  intercept ~w(presence_diff new_msg change_state)

  # def handle_out("new_msg", message, socket = %{assigns: %{state: 0}}) do
  #   push socket, "new_msg", message
  #   {:noreply, socket}
  # end
  def handle_out("change_state", %{"users" => users}, socket = %{assigns: %{user: user}}) do
    if meta = Map.get(users, user), do: Presence.update(socket, user, meta)
    {:noreply, socket}
  end
  def handle_out(_cmd, _message, socket), do: {:noreply, socket}

  defp get_state(user, admin, opponent)
  defp get_state(user, admin, user) when not is_nil(admin) do
    2
  end
  defp get_state(user, user, opponent) when not is_nil(opponent) do
    2
  end
  defp get_state(_, _, _) do
    1
  end
end
