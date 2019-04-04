defmodule PhoenixSeaBattleWeb.Game do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  import PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattleWeb.{Presence, BoardView}
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes
  alias PhoenixSeaBattle.Game.Board

  # user states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def mount(%{id: id, user: user, token: token}, socket) do
    with pid when is_pid(pid) <- GenServer.whereis(GameSupervisor.via_tuple(id)),
         {:ok, socket} <- socket |> assign(id: id, user: user, pid: pid) |> update_state() do
      messages = Game.get_messages(pid)
      socket = assign(socket, messages: messages, error: nil, token: token)
      {:ok, socket}
    else
      _ ->
        new_socket =
          socket
          |> put_flash(:error, "You must be logged in to access that page")
          |> redirect(to: Routes.page_path(socket, :index))

        {:stop, new_socket}
    end
  end

  def render(assigns) do
    ~L"""
    <div id="game-container" class="row game container">
      <div class="column column-75">
        <div class="panel panel-default game-panel">
          <div id="state-bar" class="panel-heading state-bar">
            <%= BoardView.message(@error, @game_state) %>
          </div>
          <div id="game" class="panel-body panel-game">
            <%= render_board(@game_state, @board, @shots, @other_shots, @render_opts) %>
            <div class="row panel-sub">
              <%= sub_panel(@game_state, @board, @shots) %>
            </div>
          </div>
        </div>
        <form phx-submit="insert_message">
          <input name="chat-input" type="text" class="form-control" placeholder="Type a message..." autocomplete="off">
        </form>
      </div>

      <div class="column column-25">
        <div class="panel panel-default chat-room">
          <div class="panel-heading">
            <%= opponent_status(@opponent) %><br>
            InGame Chat:
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
          <%= link "Exit Game", to: game_path(@socket, :delete, @id), method: :delete, csrf_token: @token,
            data: [confirm: "You want leave the game?"], class: "button button-default" %>
        </td>
      </div>
    </div>
    """
  end

  def handle_event("insert_message", %{"chat-input" => msg}, socket) when msg != "" do
    username = socket.assigns.user.name
    payload = %{user: username, body: HtmlSanitizeEx.strip_tags(msg)}
    Game.new_msg(socket.assigns.pid, payload)
    {:noreply, socket}
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", key, socket = %{assigns: %{game_state: :initial}}) do
    __MODULE__.InitialEventHandle.apply_key(key, socket)
  end

  def handle_event("keydown", _key, socket) do
    {:noreply, socket}
  end

  def handle_event(event, key, socket = %{assigns: %{game_state: state}})
      when state in ~w(initial ready)a do
    __MODULE__.InitialEventHandle.apply_event(event, key, socket)
  end

  def handle_event("shot", value, socket = %{assigns: %{game_state: :move}}) do
    with {index, ""} when index >= 0 and index < 100 <- Integer.parse(value) do
      Game.shot(socket.assigns.pid, socket.assigns.user.id, index)
      {:noreply, socket}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_info({:update_messages, messages}, socket) do
    {:noreply, socket |> assign(messages: messages)}
  end

  def handle_info(:retry_connect, socket = %{assigns: %{id: id}}) do
    Logger.warn "reconnect"
    {:stop, redirect(socket, to: Routes.game_path(socket, :show, id))}
  end

  def handle_info(:update_state, socket) do
    {:ok, socket} = socket |> assign(render_opts: nil) |> update_state()
    {:noreply, socket}
  end

  def handle_info({:render_error, error}, socket) do
    ref = make_ref()
    Process.send_after(self(), {:clean_error, ref}, 3_000)
    {:noreply, socket |> assign(error: {error, ref})}
  end

  def handle_info({:clean_error, ref}, socket) do
    case socket.assigns.error do
      {_error, ^ref} -> {:noreply, socket |> assign(error: nil)}
      _ -> {:noreply, socket}
    end
  end

  def handle_info(:exit, socket) do
    socket = socket |> put_flash(:info, "Game ended because of admin out")
    {:stop, redirect(socket, to: Routes.page_path(socket, :index))}
  end

  defp update_state(socket = %{assigns: %{pid: pid, user: user = %{name: username}}}) do
    with {:ok, game_state} <- Game.get(pid, user),
         {:ok, board, shots, other_shots} <- Game.get_board_and_shots(pid, user) do
      {state, other} = get_state(username, game_state)
      set_presence("lobby", username, %{state: state, game_id: socket.assigns.id, with: other})
      set_presence("game:" <> socket.assigns.id, username, %{})

      socket
      |> assign(board: board, shots: shots, other_shots: other_shots)
      |> get_opponent(game_state, username)
      |> append_render_opts(game_state, board)
    end
  end

  defp get_state(user, %{admin: "" <> admin, opponent: user}), do: {2, admin}
  defp get_state(user, %{admin: user, opponent: "" <> opponent}), do: {2, opponent}
  defp get_state(_, _), do: {1, nil}

  defp append_render_opts(socket, %{playing: false, winner: nil}, board) do
    socket
    |> assign(game_state: :initial)
    |> __MODULE__.RenderOpts.update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: {:ready, user_id}, winner: nil}, board) do
    state = if socket.assigns.user.id == user_id, do: :ready, else: :initial

    socket
    |> assign(game_state: state)
    |> __MODULE__.RenderOpts.update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: true, turn: user_id}, _board) do
    state = if socket.assigns.user.id == user_id, do: :move, else: :await
    {:ok, socket |> assign(game_state: state, render_opts: nil)}
  end

  defp append_render_opts(socket, %{playing: false, winner: user_id}, _board) do
    state = if socket.assigns.user.id == user_id, do: :win, else: :lose
    {:ok, socket |> assign(game_state: state, render_opts: nil)}
  end

  defp render_board(state, board, _, _, %{ready: true}) when state in ~w(initial ready)a do
    assigns = [board: Stream.with_index(board), shots: [], move?: false]
    BoardView.render("board.html", assigns)
  end

  defp render_board(state, board, _, _, %{x: x, y: y, pos: pos, l: l})
       when state in ~w(initial ready)a do
    pre_ship_blocks = __MODULE__.RenderOpts.make_pre_ship(x, y, pos, l)
    board = __MODULE__.RenderOpts.append_pre_ship(board, pre_ship_blocks)
    assigns = [board: board, shots: [], move?: false]
    BoardView.render("board.html", assigns)
  end

  defp render_board(state, _, shots, other_shots, _) when state in ~w(win lose)a do
    assigns = [board: Stream.with_index(other_shots), shots: shots]
    BoardView.render("final_board.html", assigns)
  end

  defp render_board(state, _, shots, other_shots, _) when state in ~w(move await)a do
    assigns = [board: Stream.with_index(other_shots), shots: shots, move?: state == :move]
    BoardView.render("board.html", assigns)
  end

  defp set_presence(topic, username, meta) do
    with {_username, %{metas: [old_meta | _]}} <-
           topic |> Presence.list() |> Enum.find(&(elem(&1, 0) == username)),
         true <- Enum.all?(meta, fn {k, v} -> Map.get(old_meta, k) == v end) do
      :ok
    else
      false -> {:ok, _} = Presence.update(self(), topic, username, meta)
      nil -> {:ok, _} = Presence.track(self(), topic, username, meta)
    end
  end

  defp sub_panel(:initial, board, _) do
    BoardView.render("sub_panel_initial.html", board: board)
  end

  defp sub_panel(:ready, _board, _) do
    BoardView.render("sub_panel_ready.html", %{})
  end

  defp sub_panel(_state, _board, shots) do
    BoardView.render("sub_panel_game.html", left: Board.left_ships(shots))
  end

  defp get_opponent(socket, %{admin: username, opponent: opponent}, username) do
    assign(socket, opponent: opponent)
  end

  defp get_opponent(socket, %{admin: opponent, opponent: username}, username) do
    assign(socket, opponent: opponent)
  end

  defp opponent_status(nil) do
    ~E"""
    No opponent
    """
  end

  defp opponent_status(opponent) do
    ~E"""
    Opponent: <%= opponent %>
    """
  end
end
