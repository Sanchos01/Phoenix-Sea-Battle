defmodule PhoenixSeaBattleWeb.Game.Playing do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias PhoenixSeaBattleWeb.Game.Rendering

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
end
