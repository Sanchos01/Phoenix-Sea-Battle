defmodule PhoenixSeaBattleWeb.BoardView do
  use PhoenixSeaBattleWeb, :view
  alias PhoenixSeaBattle.Game.Board
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a

  def left_to_place(board) do
    placed = board |> Board.left_ships() |> Enum.reduce(0, fn {_, v}, acc -> acc + v end)
    length(@marks) - placed
  end

  def render_user(assigns = %{user: user, meta: %{state: 0}}) do
    ~H"""
    <%= user %>
    <br>
    <small>in lobby</small>
    """
  end

  def render_user(assigns = %{user: user, meta: %{state: 1, game_id: game_id}}) do
    ~H"""
    <%= user %>
    <br>
    <small>in game</small>
    <a class="btn btn-default btn-xs" href={"/game/#{game_id}"}>Join</a>
    """
  end

  def render_user(assigns = %{user: user, meta: %{state: 2, with: opponent}}) do
    ~H"""
    <%= user %>
    <br>
    <small>in game with <%= opponent %></small>
    """
  end

  def render_user(assigns = %{user: user, meta: %{state: 3}}) do
    ~H"""
    <%= user %>
    <br>
    <small>game ended</small>
    """
  end

  def message(assigns = %{error: {:cross, _}, game_state: _}) do
    ~H"""
    <div class="error">
    Ships shouldn't cross
    </div>
    """
  end

  def message(assigns = %{error: {:nearest, _}, game_state: _}) do
    ~H"""
    <div class="error">
    Ships shouldn't touch
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :initial}) do
    ~H"""
    <div>
    Place your ships
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :ready}) do
    ~H"""
    <div>
    Ready, await your opponent
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :move}) do
    ~H"""
    <div>
    Make your move
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :await}) do
    ~H"""
    <div>
    Wait the opponent's move
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :win}) do
    ~H"""
    <div>
    Congratulations, you win
    </div>
    """
  end

  def message(assigns = %{error: nil, game_state: :lose}) do
    ~H"""
    <div>
    You lose, good luck next time
    </div>
    """
  end

  defp render_cell(cell, i \\ 0)

  defp render_cell(k, i) when k in [nil, :near] do
    assigns = %{}

    ~H"""
    <div phx-value={i} class="cell">
    </div>
    """
  end

  defp render_cell(:ghost, i) do
    assigns = %{}

    ~H"""
    <div phx-value={i} class="cell ghost_cell">
    </div>
    """
  end

  defp render_cell(:cross, i) do
    assigns = %{}

    ~H"""
    <div phx-value={i} class="cell cross_cell">
    </div>
    """
  end

  defp render_cell(mark, i) when mark in @marks do
    assigns = %{}

    ~H"""
    <div phx-value={i} class="cell ship_cell">
    </div>
    """
  end

  defp render_cell(:shotted, _) do
    assigns = %{}

    ~H"""
    <div class="cell shotted_cell">
    </div>
    """
  end

  defp render_cell(:killed, _) do
    assigns = %{}

    ~H"""
    <div class="cell killed_cell">
    </div>
    """
  end

  defp render_cell(:miss, _) do
    assigns = %{}

    ~H"""
    <div class="cell missed_cell">
    </div>
    """
  end

  defp render_shot(key, index, move?)

  defp render_shot(k, index, true) when is_nil(k) or k in @marks do
    assigns = %{}

    ~H"""
    <button class="cell empty-cell empty-button" phx-click="shot" phx-value-index={index}>
    </button>
    """
  end

  defp render_shot(k, _index, false) when is_nil(k) or k in @marks do
    assigns = %{}

    ~H"""
    <div class="cell empty_cell">
    </div>
    """
  end

  defp render_shot(:near, _index, _) do
    assigns = %{}

    ~H"""
    <div class="cell near_cell">
    </div>
    """
  end

  defp render_shot(:miss, _index, _) do
    assigns = %{}

    ~H"""
    <div class="cell missed_cell">
    </div>
    """
  end

  defp render_shot(:shotted, _index, _) do
    assigns = %{}

    ~H"""
    <div class="cell shotted_cell">
    </div>
    """
  end

  defp render_shot(:killed, _index, _) do
    assigns = %{}

    ~H"""
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
    assigns = %{}

    ~H"""
    Ship to place:
    <%= if pos == :h do %>
      <div class="ghost_ship_horizontal">
        <%= for _ <- Stream.cycle([nil]) |> Stream.take(l) do %>
          <%= render_cell(:ghost) %>
        <% end %>
      </div>
    <% else %>
      <div class="ghost_ship_vertical">
        <%= for _ <- Stream.cycle([nil]) |> Stream.take(l) do %>
          <%= render_cell(:ghost) %>
        <% end %>
      </div>
    <% end %>
    """
  end

  def render_placing_ship(_) do
    assigns = %{}

    ~H"""
    All ships placed
    """
  end
end
