defmodule PhoenixSeaBattleWeb.Game.Initial do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattle.Game.Board
  alias PhoenixSeaBattle.Game
  alias PhoenixSeaBattleWeb.Game.Rendering

  def render(assigns) do
    ~L"""
    """
  end

  def update_render_opts(socket, board) do
    case socket.assigns do
      %{render_opts: %{x: _x, y: _y, pos: _pos, l: _l}} ->
        {:ok, socket}

      _ ->
        case Board.prepare(board) do
          :ok ->
            {:ok, socket |> assign(render_opts: %{ready: true})}

          {_type, l} when l in 1..4 ->
            {:ok, assign(socket, render_opts: %{x: 0, y: 0, pos: :h, l: l})}
        end
    end
  end

  def render_board(board, %{ready: true}) do
    board
    |> Enum.with_index()
    |> Rendering.render_boards()
  end

  def render_board(board, %{x: x, y: y, pos: pos, l: l}) do
    pre_ship_blocks = make_pre_ship(x, y, pos, l)

    board
    |> append_pre_ship(pre_ship_blocks)
    |> Rendering.render_boards()
  end

  def sub_commands(:initial, board) do
    ~E"""
    <div class="column column-20 button-small">
      <button phx-click="drop_last" style="width: 85%">Drop last</button>
    </div>
    <div class="column column-20 button-small">
      <button phx-click="drop_all" style="width: 85%">Drop all</button>
    </div>
    <%= if Board.prepare(board) == :ok do %>
      <div class="column column-20 button-small">
        <button phx-click="ready" style="width: 85%">Ready</button>
      </div>
    <% end %>
    """
  end

  def sub_commands(:ready, _board) do
    ~E"""
    <div class="column column-20 button-small">
      <button phx-click="unready" style="width: 85%">Unready</button>
    </div>
    """
  end

  defp make_pre_ship(x, y, pos, l) when x < 0 do
    make_pre_ship(0, y, pos, l)
  end

  defp make_pre_ship(x, y, pos, l) when y < 0 do
    make_pre_ship(x, 0, pos, l)
  end

  defp make_pre_ship(x, y, :h, l) when x + l > 10 do
    make_pre_ship(10 - l, y, :h, l)
  end

  defp make_pre_ship(x, y, :v, l) when y + l > 10 do
    make_pre_ship(x, 10 - l, :v, l)
  end

  defp make_pre_ship(x, y, p, l) do
    Board.ship_opts_to_indexes(x, y, p, l)
  end

  defp append_pre_ship(list, pre_ship_blocks) do
    pre_ship_blocks
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
    |> Stream.with_index()
  end

  def apply_key(_key, socket = %{assigns: %{render_opts: %{ready: true}}}) do
    {:noreply, socket}
  end

  def apply_key("ArrowLeft", socket) do
    render_opts = socket.assigns.render_opts

    if can_decrease_x?(render_opts) do
      new_render_opts = %{render_opts | x: render_opts.x - 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowRight", socket) do
    render_opts = socket.assigns.render_opts

    if can_increase_x?(render_opts) do
      new_render_opts = %{render_opts | x: render_opts.x + 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowUp", socket) do
    render_opts = socket.assigns.render_opts

    if can_decrease_y?(render_opts) do
      new_render_opts = %{render_opts | y: render_opts.y - 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowDown", socket) do
    render_opts = socket.assigns.render_opts

    if can_increase_y?(render_opts) do
      new_render_opts = %{render_opts | y: render_opts.y + 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key(k, socket) when k in ~w(- _) do
    render_opts = socket.assigns.render_opts

    new_render_opts =
      case render_opts do
        %{pos: :h, y: y, l: l} ->
          if l + y > 10 do
            %{render_opts | pos: :v, y: 10 - l}
          else
            %{render_opts | pos: :v}
          end

        %{pos: :v, x: x, l: l} ->
          if l + x > 10 do
            %{render_opts | pos: :h, x: 10 - l}
          else
            %{render_opts | pos: :h}
          end
      end

    {:noreply, assign(socket, render_opts: new_render_opts)}
  end

  def apply_key(k, socket = %{assigns: assigns}) when k in ~w(+ =) do
    Game.apply_ship(assigns.pid, assigns.user.id, assigns.render_opts)
    {:noreply, socket}
  end

  def apply_key(_key, socket) do
    {:noreply, socket}
  end

  def apply_event("drop_last", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_last(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("drop_all", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_all(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("ready", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.ready(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("unready", _key, socket = %{assigns: %{game_state: :ready}}) do
    Game.unready(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event(event, _key, socket) do
    IO.puts("event: #{inspect(event)} ; #{inspect(socket)}")
    {:noreply, socket}
  end

  defp can_decrease_x?(%{x: x}) do
    x > 0
  end

  defp can_increase_x?(%{x: x, pos: pos, l: l}) do
    case pos do
      :h -> x + l < 10
      :v -> x < 9
    end
  end

  defp can_decrease_y?(%{y: y}) do
    y > 0
  end

  defp can_increase_y?(%{y: y, pos: pos, l: l}) do
    case pos do
      :v -> y + l < 10
      :h -> y < 9
    end
  end
end
