defmodule PhoenixSeaBattleWeb.Game do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  import PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  # alias PhoenixSeaBattle.Game.Board
  # alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes

  # user states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def mount(%{id: id, user: user}, socket) do
    with pid when is_pid(pid) <- GenServer.whereis(GameSupervisor.via_tuple(id)),
         r when is_reference(r) <- Process.monitor(pid)
    do
      # add presence tracking
      # Endpoint.subscribe("game:" <> id)
      username = user.username
      {:ok, game_state} = Game.get(pid, username)
      state = get_state(username, game_state)
      {:ok, _} = Presence.track(self(), "lobby", username, %{state: state, game_id: id})
      {:ok, _} = Presence.track(self(), "game:" <> id, username, %{})
      board = get_board(game_state, username)
      socket
      |> assign(id: id, user: user, pid: pid, board: board, messages: game_state.messages)
      |> append_render_opts(game_state, board)
    else
      _ ->
        {:stop, socket |> redirect(to: Routes.game_path(socket, :show, id))}
    end
  end

  def render(assigns) do
    ~L"""
    <div id="game-container" class="row game container">
      <div class="column column-67">
        <div class="panel panel-default game-panel">
          <div id="state-bar" class="panel-heading state-bar">
            <%= message(@game_state) %>
          </div>
          <div id="game" class="panel-body panel-game">
            <%= render_game(@game_state, @board, @render_opts) %>
          </div>
        </div>
        <form phx-submit="insert_message">
          <input name="chat-input" type="text" class="form-control" placeholder="Type a message..." autocomplete="off">
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
            <%= for msg <- Enum.reverse(@messages) do %>
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
    payload = %{user: username, body: HtmlSanitizeEx.strip_tags(msg)}
    Game.new_msg(socket.assigns.pid, payload)
    {:noreply, socket}
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_info({:update_messages, messages}, socket) do
    {:noreply, socket |> assign(messages: messages)}
  end

  # def handle_info(%Broadcast{}, socket) do
  #   {:ok, game_state} = Game.get(socket.assigns.pid, socket.assigns.user.username)
  #   {:noreply, assign(socket, game_state: game_state)}
  # end

  defp get_state(user, %{admin: admin, opponent: user}) when not is_nil(admin), do: 2
  defp get_state(user, %{admin: user, opponent: opponent}) when not is_nil(opponent), do: 2
  defp get_state(_, _), do: 1

  defp message(:initial) do
    ~E"""
    Place your ships
    """
  end

  defp get_board(%{admin: username, admin_board: board}, username), do: board
  defp get_board(%{opponent: username, opponent_board: board}, username), do: board

  defp append_render_opts(socket, %{playing: false, ended: false}, board) do
    socket
    |> assign(game_state: :initial)
    |> __MODULE__.Initial.update_render_opts(board)
  end

  defp render_game(:initial, board, render_opts) do
    __MODULE__.Initial.render_game(board, render_opts)
  end
end