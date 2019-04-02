defmodule PhoenixSeaBattleWeb.BoardView do
  use PhoenixSeaBattleWeb, :view
  alias PhoenixSeaBattle.Game.Board
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a

  def render_user(user, %{state: 0}) do
    ~E"""
    <%= user %>
    <br>
    <small>in lobby</small>
    """
  end

  def render_user(user, %{state: 1, game_id: game_id}) do
    ~E"""
    <%= user %>
    <br>
    <small>in game</small>
    <a class="btn btn-default btn-xs" href="/game/<%= game_id %>">Join</a>
    """
  end

  def render_user(user, %{state: 2, with: opponent}) do
    ~E"""
    <%= user %>
    <br>
    <small>in game with <%= opponent %></small>
    """
  end

  def render_user(user, %{state: 3}) do
    ~E"""
    <%= user %>
    <br>
    <small>game ended</small>
    """
  end

  def message({:cross, _}, _) do
    ~E"""
    <div class="error">
    Ships shouldn't cross
    </div>
    """
  end

  def message({:nearest, _}, _) do
    ~E"""
    <div class="error">
    Ships shouldn't touch
    </div>
    """
  end

  def message(nil, :initial) do
    ~E"""
    <div>
    Move your ships with arrows, use '-' for rotating and '+' for placing
    </div>
    """
  end

  def message(nil, :ready) do
    ~E"""
    <div>
    Ready, await your opponent
    </div>
    """
  end

  def message(nil, :move) do
    ~E"""
    <div>
    Make your move
    </div>
    """
  end

  def message(nil, :await) do
    ~E"""
    <div>
    Wait the opponent's move
    </div>
    """
  end

  def message(nil, :win) do
    ~E"""
    <div>
    Congratulations, you win
    </div>
    """
  end

  def message(nil, :lose) do
    ~E"""
    <div>
    You lose, good luck next time
    </div>
    """
  end

  defp render_block(block, index, left? \\ true)

  defp render_block(k, index, left?) when k in [nil, :near] do
    ~E"""
    <div class="block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(:ghost, index, left?) do
    ~E"""
    <div class="block ghost_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(:cross, index, left?) do
    ~E"""
    <div class="block cross_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(mark, index, left?) when mark in @marks do
    ~E"""
    <div class="block ship_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(:shotted, index, left?) do
    ~E"""
    <div class="block shotted_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(:killed, index, left?) do
    ~E"""
    <div class="block killed_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_block(:miss, index, left?) do
    ~E"""
    <div class="block missed_block" style="<%= position_style_by_index(index, left?) %>">
    </div>
    """
  end

  defp render_shot(k, index, true) when is_nil(k) or k in @marks do
    ~E"""
    <div style="width: 1.3em; height: 1.3em; position: absolute; <%= position_style_by_index(index, false) %>">
      <button class="block empty-block empty-button" phx-click="shot" phx-value=<%= index %>>
      </button>
    </div>
    """
  end

  defp render_shot(k, index, false) when is_nil(k) or k in @marks do
    ~E"""
    <div class="block empty_block" style="<%= position_style_by_index(index, false) %>">
    </div>
    """
  end

  defp render_shot(:near, index, _) do
    ~E"""
    <div class="block near_block" style="<%= position_style_by_index(index, false) %>">
    </div>
    """
  end

  defp render_shot(:miss, index, _) do
    ~E"""
    <div class="block missed_block" style="<%= position_style_by_index(index, false) %>">
    </div>
    """
  end

  defp render_shot(:shotted, index, _) do
    ~E"""
    <div class="block shotted_block" style="<%= position_style_by_index(index, false) %>">
    </div>
    """
  end

  defp render_shot(:killed, index, _) do
    ~E"""
    <div class="block killed_block" style="<%= position_style_by_index(index, false) %>">
    </div>
    """
  end

  defp render_shot(k, index, _) do
    render_block(k, index)
  end

  defp position_style_by_index(index, board?) do
    left = Float.ceil(rem(index, 10) * 1.5, 2) + if board?, do: 3, else: 18.7
    top = Float.ceil(div(index, 10) * 1.5, 2) + 3.5

    ~E"""
    left: <%= left %>em; top: <%= top %>em
    """
  end

  defp apply_shots([]), do: Board.new_board() |> Stream.with_index()
  defp apply_shots(shots = [_ | _]), do: Stream.with_index(shots)
end
