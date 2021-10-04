defmodule PhoenixSeaBattleWeb.BoardView do
  use PhoenixSeaBattleWeb, :view
  alias PhoenixSeaBattle.Game.Board
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a

  def left_to_place(board) do
    placed = board |> Board.left_ships() |> Enum.reduce(0, fn {_, v}, acc -> acc + v end)
    length(@marks) - placed
  end

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
    Place your ships
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

  defp render_cell(cell, i \\ 0)

  defp render_cell(k, i) when k in [nil, :near] do
    ~E"""
    <div phx-value=<%= i %> class="cell">
    </div>
    """
  end

  defp render_cell(:ghost, i) do
    ~E"""
    <div phx-value=<%= i %> class="cell ghost_cell">
    </div>
    """
  end

  defp render_cell(:cross, i) do
    ~E"""
    <div phx-value=<%= i %> class="cell cross_cell">
    </div>
    """
  end

  defp render_cell(mark, i) when mark in @marks do
    ~E"""
    <div phx-value=<%= i %> class="cell ship_cell">
    </div>
    """
  end

  defp render_cell(:shotted, _) do
    ~E"""
    <div class="cell shotted_cell">
    </div>
    """
  end

  defp render_cell(:killed, _) do
    ~E"""
    <div class="cell killed_cell">
    </div>
    """
  end

  defp render_cell(:miss, _) do
    ~E"""
    <div class="cell missed_cell">
    </div>
    """
  end

  defp render_shot(key, index, move?)

  defp render_shot(k, index, true) when is_nil(k) or k in @marks do
    ~E"""
    <button class="cell empty-cell empty-button" phx-click="shot" phx-value-index=<%= index %>>
    </button>
    """
  end

  defp render_shot(k, _index, false) when is_nil(k) or k in @marks do
    ~E"""
    <div class="cell empty_cell">
    </div>
    """
  end

  defp render_shot(:near, _index, _) do
    ~E"""
    <div class="cell near_cell">
    </div>
    """
  end

  defp render_shot(:miss, _index, _) do
    ~E"""
    <div class="cell missed_cell">
    </div>
    """
  end

  defp render_shot(:shotted, _index, _) do
    ~E"""
    <div class="cell shotted_cell">
    </div>
    """
  end

  defp render_shot(:killed, _index, _) do
    ~E"""
    <div class="cell killed_cell">
    </div>
    """
  end

  defp render_shot(k, _, _) do
    render_cell(k)
  end

  defp apply_shots([]), do: Board.new_board() |> Stream.with_index()
  defp apply_shots(shots = [_ | _]), do: Stream.with_index(shots)

  def render_placing_ship(%{pos: pos, l: l}) do
    ~E"""
    Ship to place:
    <%= if pos == :h do %>
      <div class=ghost_ship_horizontal>
        <%= for _ <- Stream.cycle([nil]) |> Stream.take(l) do %>
          <%= render_cell(:ghost) %>
        <% end %>
      </div>
    <% else %>
      <div class=ghost_ship_vertical>
        <%= for _ <- Stream.cycle([nil]) |> Stream.take(l) do %>
          <%= render_cell(:ghost) %>
        <% end %>
      </div>
    <% end %>
    """
  end

  def render_placing_ship(_) do
    ~E"""
    All ships placed
    """
  end
end
