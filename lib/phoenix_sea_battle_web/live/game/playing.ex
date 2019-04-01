defmodule PhoenixSeaBattleWeb.Game.Playing do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattleWeb.Game.Rendering
  alias PhoenixSeaBattle.Game.Board

  def render(assigns) do
    ~L"""
    """
  end

  def update_render_opts(socket, _board) do
    {:ok, assign(socket, render_opts: nil)}
  end

  def render_board(state, _board, shots, other_shots) when state in ~w(win lose)a do
    other_shots
    |> Enum.with_index()
    |> Rendering.render_final_boards(shots)
  end

  def render_board(state, _board, shots, other_shots) when state in ~w(move await)a do
    other_shots
    |> Enum.with_index()
    |> Rendering.render_boards(shots, state == :move)
  end

  def sub_panel(shots) do
    left = Board.left_ships(shots)
    ~E"""
    <div style="padding-right: 1em; padding-top: 0.6em">4-fielded - <%= left[4] %>;</div>
    <div style="padding-right: 1em; padding-top: 0.6em">3-fielded - <%= left[3] %>;</div>
    <div style="padding-right: 1em; padding-top: 0.6em">2-fielded - <%= left[2] %>;</div>
    <div style="padding-right: 1em; padding-top: 0.6em">1-fielded - <%= left[1] %>;</div>
    """
  end
end
