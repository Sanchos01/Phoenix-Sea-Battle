defmodule PhoenixSeaBattleWeb.Game do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  import PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattleWeb.{Endpoint, Presence}
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  alias Phoenix.Socket.Broadcast

  # states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def mount(%{id: id, user: user}, socket) do
    Endpoint.subscribe("game:" <> id)
    pid = GenServer.whereis(GameSupervisor.via_tuple(id))
    Process.monitor(pid)
    {:ok, game_state} = Game.get(pid, user.username)
    state = get_state(user, game_state)
    {:ok, _} = Presence.track(self(), "lobby", user.username, %{state: state, game_id: id})
    {:ok, _} = Presence.track(self(), "game:" <> id, user.username, %{})
    {:ok, assign(socket, id: id, user: user, pid: pid, game_state: game_state)}
  end

  def render(assigns) do
    ~L"""
    <div id="game-container" class="row game container">
      <div class="column column-67">
        <div class="panel panel-default game-panel">
          <div id="state-bar" class="panel-heading state-bar">
            State bar
            <div id="game-control">
            </div>
          </div>
          <div id="game" class="panel-body panel-game">
          </div>
        </div>
        <form phx-submit="insert_message">
          <input name="chat-input" type="text" class="form-control" placeholder="Type a message...">
        </form>
      </div>

      <div class="column">
        <div class="panel panel-default chat-room">
          <div class="panel-heading">
            InGame Chat
            <td id="game-control" class="text-right">
            </td>
          </div>
          <div id="messages" class="panel-body panel-messages">
            <%= for msg <- Enum.reverse(@game_state.messages) do %>
            <div>
            <%= "#{msg.user}: #{msg.body}" %>
            </div>
            <% end %>
          </div>
        </div>
        <td class="text-right">
          <%= link "Exit Game", to: page_path(@socket, :index),
            data: [confirm: "You want leave the game?"], class: "button button-default" %>
        </td>
      </div>
    </div>
    """
  end

  def handle_event("insert_message", %{"chat-input" => msg}, socket) when msg != "" do
    username = socket.assigns.user.username
    Endpoint.broadcast("game:" <> socket.assigns.id, "new_msg", %{user: username, body: msg})
    {:noreply, socket}
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_info(%Broadcast{}, socket) do
    {:ok, game_state} = Game.get(socket.assigns.pid, socket.assigns.user.username)
    {:noreply, assign(socket, game_state: game_state)}
  end

  defp get_state(user, %{admin: admin, opponent: user}) when not is_nil(admin), do: 2
  defp get_state(user, %{admin: user, opponent: opponent}) when not is_nil(opponent), do: 2
  defp get_state(_, _), do: 1
end