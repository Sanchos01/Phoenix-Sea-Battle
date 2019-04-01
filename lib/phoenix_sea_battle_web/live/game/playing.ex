defmodule PhoenixSeaBattleWeb.Game.Playing do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattle.Game.Board
  alias PhoenixSeaBattleWeb.Game.Rendering

  def render(assigns) do
    ~L"""
    """
  end

  def update_render_opts(socket, _board) do
    {:ok, assign(socket, render_opts: nil)}
  end

  def render_board(state, board, shots, other_shots) do
    board
    |> Board.apply_shots(other_shots)
    |> Enum.with_index()
    |> Rendering.render_boards(shots, state == :move)
  end
end
