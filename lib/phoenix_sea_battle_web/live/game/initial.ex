defmodule PhoenixSeaBattleWeb.Game.Initial do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattle.Game.Board
  alias PhoenixSeaBattle.Game
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a

  def render(assigns) do
    ~L"""
    <div phx-keydown="keydown" phx-target="window">
      <%= for {block, index} <- @blocks do %>
        <%= render_block(block, index) %>
      <% end %>
    </div>
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
    ~E"""
    <div phx-keydown="keydown" phx-target="window">
      <%= for {block, index} <- board do %>
        <%= render_block(block, index) %>
      <% end %>
    </div>
    """
  end

  def render_board(board, %{x: x, y: y, pos: pos, l: l}) do
    pre_ship_blocks = make_pre_ship(x, y, pos, l)
    blocks = append_pre_ship(board, pre_ship_blocks)
    ~E"""
    <div phx-keydown="keydown" phx-target="window">
      <%= for {block, index} <- blocks do %>
        <%= render_block(block, index) %>
      <% end %>
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
    Enum.reduce(pre_ship_blocks, list, fn index, acc ->
      case Enum.at(acc, index) do
        0 -> List.replace_at(acc, index, :ghost)
        _ -> List.replace_at(acc, index, :cross)
      end
    end)
    |> Stream.with_index()
  end

  defp render_block(0, index) do
    ~E"""
    <div class="block" <%= position_style_by_index(index) %>>
    </div>
    """
  end
  defp render_block(:ghost, index) do
    ~E"""
    <div class="block ghost_block" <%= position_style_by_index(index) %>>
    </div>
    """
  end
  defp render_block(:cross, index) do
    ~E"""
    <div class="block cross_block" <%= position_style_by_index(index) %>>
    </div>
    """
  end
  defp render_block(mark, index) when mark in @marks do
    ~E"""
    <div class="block ship_block" <%= position_style_by_index(index) %>>
    </div>
    """
  end
  defp render_block(x, index) do
    IO.puts "x? #{inspect x}"
    ~E"""
    <div class="block" <%= position_style_by_index(index) %>>
    </div>
    """
  end

  defp position_style_by_index(index) do
    left = Float.ceil(rem(index, 10) * 1.4, 2) + 3
    top = Float.ceil(div(index, 10) * 1.4, 2) + 4
    ~E"""
    style="left: <%= left %>em; top: <%= top %>em"
    """
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

  def apply_key(" ", socket) do
    render_opts = socket.assigns.render_opts
    new_render_opts = case render_opts do
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

  def apply_key("Enter", socket = %{assigns: assigns}) do
    Game.apply_ship(assigns.pid, assigns.user.name, assigns.render_opts)
    {:noreply, socket}
  end

  def apply_key(_key, socket) do
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