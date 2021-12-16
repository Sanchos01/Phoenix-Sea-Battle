defmodule PhoenixSeaBattleWeb.Game do
  use PhoenixSeaBattleWeb, :live_view
  require Logger
  import PhoenixSeaBattleWeb.Router.Helpers
  alias PhoenixSeaBattleWeb.{Presence, BoardView}
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor
  alias PhoenixSeaBattle.GameServer
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes
  alias PhoenixSeaBattle.Game.Board

  @error_timeout Application.get_env(:phoenix_sea_battle, :game_live_timeout, 3_000)

  # user states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  def mount(_params, %{"id" => id, "user" => user, "token" => token}, socket) do
    socket =
      assign(socket,
        id: id,
        user: user,
        token: token,
        pid: nil,
        error: nil,
        game_state: :initial,
        messages: [],
        board: Board.new_board(),
        shots: [],
        other_shots: [],
        render_opts: %{ready: true},
        opponent: nil
      )

    with true <- connected?(socket),
         pid when is_pid(pid) <- GenServer.whereis(GameSupervisor.via_tuple(id)),
         {:ok, socket} <- socket |> assign(pid: pid) |> update_state() do
      messages = GameServer.get_messages(pid)
      socket = assign(socket, messages: messages, error: nil)
      {:ok, socket}
    else
      false ->
        {:ok, socket}

      _ ->
        {:ok, redirect(socket, to: Routes.game_path(socket, :show, id))}
    end
  end

  def handle_event("insert_message", %{"chat-input" => msg}, socket) when msg != "" do
    username = socket.assigns.user.name
    payload = %{user: username, body: HtmlSanitizeEx.strip_tags(msg)}
    GameServer.new_msg(socket.assigns.pid, payload)
    {:noreply, socket}
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_event(event, key, socket = %{assigns: %{game_state: state}})
      when state in ~w(initial ready)a do
    case __MODULE__.InitialEventHandle.apply_event(event, key, socket) do
      {:ok, new_assigns} ->
        {:noreply, assign(socket, new_assigns)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("shot", %{"index" => value}, socket = %{assigns: %{game_state: :move}}) do
    {index, ""} = Integer.parse(value)
    GameServer.shot(socket.assigns.pid, socket.assigns.user.id, index)
    {:noreply, socket}
  end

  def handle_info({:update_messages, messages}, socket) do
    {:noreply, socket |> assign(messages: messages)}
  end

  def handle_info(:retry_connect, socket = %{assigns: %{id: id}}) do
    {:noreply, redirect(socket, to: Routes.game_path(socket, :show, id))}
  end

  def handle_info(:update_state, socket) do
    {:ok, socket} = socket |> assign(render_opts: nil) |> update_state()
    {:noreply, socket}
  end

  def handle_info({:render_error, error}, socket) do
    ref = make_ref()
    Process.send_after(self(), {:clean_error, ref}, @error_timeout)
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
    {:noreply, redirect(socket, to: Routes.page_path(socket, :index))}
  end

  defp update_state(socket = %{assigns: %{pid: pid, user: user = %{name: username}}}) do
    with {:ok, game_state} <- GameServer.get(pid, user),
         {:ok, board, shots, other_shots} <- GameServer.get_board_and_shots(pid, user) do
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
    |> update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: {:ready, user_id}, winner: nil}, board) do
    state = if socket.assigns.user.id == user_id, do: :ready, else: :initial

    socket
    |> assign(game_state: state)
    |> update_render_opts(board)
  end

  defp append_render_opts(socket, %{playing: true, turn: user_id}, _board) do
    state = if socket.assigns.user.id == user_id, do: :move, else: :await
    {:ok, socket |> assign(game_state: state, render_opts: nil)}
  end

  defp append_render_opts(socket, %{playing: false, winner: user_id}, _board) do
    state = if socket.assigns.user.id == user_id, do: :win, else: :lose
    {:ok, socket |> assign(game_state: state, render_opts: nil)}
  end

  defp render_board(state, board, _, _, render_opts = %{ready: true})
       when state in ~w(initial ready)a do
    assigns = [board: board, shots: [], move?: false, render_opts: render_opts]
    BoardView.render("preparation_board.html", assigns)
  end

  defp render_board(state, board, _, _, render_opts = %{x: x, y: y, pos: pos, l: l})
       when state in ~w(initial ready)a do
    pre_ship_cells = Board.ship_opts_to_indexes(x, y, pos, l)
    board = append_pre_ship(board, pre_ship_cells)
    assigns = [board: board, shots: [], move?: false, render_opts: render_opts]
    BoardView.render("preparation_board.html", assigns)
  end

  defp render_board(state, _, shots, other_shots, _) when state in ~w(win lose)a do
    assigns = [board: other_shots, shots: shots]
    BoardView.render("final_board.html", assigns)
  end

  defp render_board(state, _, shots, other_shots, _) when state in ~w(move await)a do
    assigns = [board: other_shots, shots: shots, move?: state == :move]
    BoardView.render("board.html", assigns)
  end

  defp set_presence(topic, username, meta) do
    with {_, %{metas: [old_meta | _]}} <- find_user_in_presence(topic, username),
         false <- Enum.all?(meta, fn {k, v} -> Map.get(old_meta, k) == v end),
         {:error, _} <- Presence.update(self(), topic, username, meta) do
      {:ok, _} = Presence.track(self(), topic, username, meta)
    else
      true -> :ok
      {:ok, _} -> :ok
      nil -> {:ok, _} = Presence.track(self(), topic, username, meta)
    end
  end

  defp find_user_in_presence(topic, username) do
    topic
    |> Presence.list()
    |> Enum.find(fn
      {^username, _} -> true
      _ -> false
    end)
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
    assigns = %{}

    ~H"""
    No opponent
    """
  end

  defp opponent_status(opponent) do
    assigns = %{}

    ~H"""
    Opponent: <%= opponent %>
    """
  end

  defp update_render_opts(socket = %{assigns: %{render_opts: %{x: _, y: _, pos: _, l: _}}}, _) do
    {:ok, socket}
  end

  defp update_render_opts(socket, board) do
    case Board.prepare(board) do
      :ok ->
        {:ok, socket |> assign(render_opts: %{ready: true})}

      {_type, l} when l in 1..4 ->
        {:ok, assign(socket, render_opts: %{ready: false, x: 0, y: 0, pos: :h, l: l})}
    end
  end

  defp append_pre_ship(list, pre_ship_cells) do
    pre_ship_cells
    |> Enum.reduce(list, fn index, acc ->
      case Enum.at(acc, index) do
        nil ->
          index
          |> Board.near_indexes()
          |> Enum.any?(&(Enum.at(list, &1) not in [nil, :ghost, :cross]))
          |> if do
            List.replace_at(acc, index, :cross)
          else
            List.replace_at(acc, index, :ghost)
          end

        _ ->
          List.replace_at(acc, index, :cross)
      end
    end)
  end
end
