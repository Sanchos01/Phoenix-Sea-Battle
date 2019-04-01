defmodule PhoenixSeaBattleWeb.Game do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger
  import PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.Game
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes

  # user states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def mount(%{id: id, user: user}, socket) do
    with pid when is_pid(pid) <- GenServer.whereis(GameSupervisor.via_tuple(id)),
         ref when is_reference(ref) <- Process.monitor(pid),
         {:ok, socket} <- socket |> assign(id: id, user: user, pid: pid) |> update_state() do
      messages = Game.get_messages(pid)
      socket = assign(socket, messages: messages, error: nil)
      {:ok, socket}
    else
      _ ->
        {:stop, socket |> redirect(to: Routes.game_path(socket, :show, id))}
    end
  end

  def render(assigns) do
    ~L"""
    <div id="game-container" class="row game container">
      <div class="column column-75">
        <div class="panel panel-default game-panel">
          <div id="state-bar" class="panel-heading state-bar">
            <%= message(@error, @game_state) %>
          </div>
          <div id="game" class="panel-body panel-game">
            <%= render_board(@game_state, @board, @shots, @other_shots, @render_opts) %>
            <div class="row panel-sub_commands">
              <%= sub_commands(@game_state, @board, @user) %>
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

  def handle_event("keydown", key, socket = %{assigns: %{game_state: :initial}}) do
    __MODULE__.Initial.apply_key(key, socket)
  end

  def handle_event("keydown", _key, socket) do
    {:noreply, socket}
  end

  def handle_event(event, key, socket = %{assigns: %{game_state: state}})
      when state in ~w(initial ready)a do
    __MODULE__.Initial.apply_event(event, key, socket)
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

  def handle_info({:DOWN, _, _, pid, _}, socket = %{assigns: assigns = %{pid: pid}}) do
    {:stop, socket |> redirect(to: Routes.game_path(socket, :show, assigns.id))}
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

  defp update_state(socket = %{assigns: %{pid: pid, user: user = %{name: username}}}) do
    {:ok, game_state} = Game.get(pid, user)
    {:ok, board, shots, other_shots} = Game.get_board_and_shots(pid, user)
    {state, other} = get_state(username, game_state)
    set_presence("lobby", username, %{state: state, game_id: socket.assigns.id, with: other})
    set_presence("game:" <> socket.assigns.id, username, %{})

    socket
    |> assign(board: board, shots: shots, other_shots: other_shots)
    |> append_render_opts(game_state, board)
  end

  defp get_state(user, %{admin: "" <> admin, opponent: user}), do: {2, admin}
  defp get_state(user, %{admin: user, opponent: "" <> opponent}), do: {2, opponent}
  defp get_state(_, _), do: {1, nil}

  defp message({:cross, _}, _) do
    ~E"""
    <div class="error">
    Ships shouldn't cross
    </div>
    """
  end

  defp message({:nearest, _}, _) do
    ~E"""
    <div class="error">
    Ships shouldn't touch
    </div>
    """
  end

  defp message(nil, :initial) do
    ~E"""
    <div>
    Move your ships with arrows, use '-' for rotating and '+' for placing
    </div>
    """
  end

  defp message(nil, :ready) do
    ~E"""
    <div>
    Ready, await your opponent
    </div>
    """
  end

  defp message(nil, :move) do
    ~E"""
    <div>
    Make your move
    </div>
    """
  end

  defp message(nil, :await) do
    ~E"""
    <div>
    Wait the opponent's move
    </div>
    """
  end

  defp append_render_opts(socket, %{playing: false, winner: nil}, board) do
    socket
    |> assign(game_state: :initial)
    |> __MODULE__.Initial.update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: {:ready, user_id}, winner: nil}, board) do
    state = if socket.assigns.user.id == user_id, do: :ready, else: :initial

    socket
    |> assign(game_state: state)
    |> __MODULE__.Initial.update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: true, turn: user_id}, board) do
    state = if socket.assigns.user.id == user_id, do: :move, else: :await

    socket
    |> assign(game_state: state)
    |> __MODULE__.Playing.update_render_opts(board)
  end

  defp render_board(state, board, _shots, _other_shots, render_opts)
       when state in ~w(initial ready)a do
    __MODULE__.Initial.render_board(board, render_opts)
  end

  defp render_board(state, board, shots, other_shots, _render_opts)
       when state in ~w(move await)a do
    __MODULE__.Playing.render_board(state, board, shots, other_shots)
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

  defp sub_commands(state, board, _user) when state in ~w(initial ready)a do
    __MODULE__.Initial.sub_commands(state, board)
  end

  defp sub_commands(_state, _board, _user), do: nil
end
