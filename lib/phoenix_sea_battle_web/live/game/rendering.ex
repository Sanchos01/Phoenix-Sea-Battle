defmodule PhoenixSeaBattleWeb.Game.Rendering do
  use Phoenix.HTML
  alias PhoenixSeaBattle.Game.Board
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a

  def render_boards(board, shots \\ []) do
    shots_board = apply_shots(shots)
    ~E"""
    <div phx-keydown="keydown" phx-target="window">
      <%= for {block, index} <- board do %>
        <%= render_block(block, index) %>
      <% end %>
      <%= for {block, index} <- shots_board do %>
        <%= render_block(block, index, false) %>
      <% end %>
    </div>
    """
  end

  defp render_block(block, index, board? \\ true)

  defp render_block(0, index, board?) do
    ~E"""
    <div class="block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(:ghost, index, board?) do
    ~E"""
    <div class="block ghost_block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(:cross, index, board?) do
    ~E"""
    <div class="block cross_block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(nil, index, board?) do
    ~E"""
    <div class="block empty_block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(:near, index, board?) do
    ~E"""
    <div class="block near_block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(mark, index, board?) when mark in @marks do
    ~E"""
    <div class="block ship_block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp render_block(x, index, board?) do
    IO.puts "x? #{inspect x}"
    ~E"""
    <div class="block" <%= position_style_by_index(index, board?) %>>
    </div>
    """
  end

  defp position_style_by_index(index, board?) do
    left = Float.ceil(rem(index, 10) * 1.4, 2) + (if board?, do: 3, else: 18.5)
    top = Float.ceil(div(index, 10) * 1.4, 2) + 4
    ~E"""
    style="left: <%= left %>em; top: <%= top %>em"
    """
  end

  defp apply_shots([]), do: Board.new_shots() |> Enum.with_index()
end