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
         {:ok, socket} <- socket |> assign(id: id, user: user, pid: pid) |> update_state()
    do
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

  def handle_event("keydown", key, socket) do
    IO.puts "keydown: #{inspect key} ; #{inspect socket}"
    {:noreply, socket}
  end

  # def handle_event("keydown", _, socket) do
  #   {:noreply, socket}
  # end

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
    state = get_state(username, game_state)
    set_presence("lobby", username, %{state: state, game_id: socket.assigns.id})
    set_presence("game:" <> socket.assigns.id, username, %{})
    socket
    |> assign(board: board, shots: shots, other_shots: other_shots)
    |> append_render_opts(game_state, board)
  end

  defp get_state(user, %{admin: admin, opponent: user}) when not is_nil(admin), do: 2
  defp get_state(user, %{admin: user, opponent: opponent}) when not is_nil(opponent), do: 2
  defp get_state(_, _), do: 1

  defp message({:cross, _}, _) do
    ~E"""
    Ships can't crossing
    """
  end

  defp message({:nearest, _}, _) do
    ~E"""
    Ships can't touching
    """
  end

  defp message(nil, :initial) do
    ~E"""
    Place your ships
    """
  end

  defp append_render_opts(socket, %{playing: false, winner: nil}, board) do
    socket
    |> assign(game_state: :initial)
    |> __MODULE__.Initial.update_render_opts(board)
  end

  defp render_board(:initial, board, _shots, _other_shots, render_opts) do
    __MODULE__.Initial.render_board(board, render_opts)
  end

  defp set_presence(topic, username, meta) do
    case topic |> Presence.list |> Enum.find(& elem(&1, 0) == username) do
      {_username, %{metas: [old_meta]}} ->
        if Enum.all?(meta, fn {k, v} -> Map.get(old_meta, k) == v end) do
          :ok
        else
          {:ok, _} = Presence.update(self(), topic, username, meta)
        end
      nil ->
        {:ok, _} = Presence.track(self(), topic, username, meta)
    end
  end
end