defmodule PhoenixSeaBattleWeb.Game.Initial do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattle.Game.Board

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
          l when l in 1..4 ->
            {:ok, assign(socket, render_opts: %{x: 0, y: 0, pos: :h, l: l})}
        end
    end
  end

  def render_game(board, %{ready: true}) do
    ~E"""
    """
  end

  def render_game(board, %{x: x, y: y, pos: pos, l: l}) do
    ~E"""
    ok
    """
  end
end