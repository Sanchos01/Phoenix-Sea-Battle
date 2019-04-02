defmodule PhoenixSeaBattleWeb.Game.RenderOpts do
  use Phoenix.LiveView
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

          {_type, l} when l in 1..4 ->
            {:ok, assign(socket, render_opts: %{x: 0, y: 0, pos: :h, l: l})}
        end
    end
  end

  def make_pre_ship(x, y, pos, l) when x < 0 do
    make_pre_ship(0, y, pos, l)
  end

  def make_pre_ship(x, y, pos, l) when y < 0 do
    make_pre_ship(x, 0, pos, l)
  end

  def make_pre_ship(x, y, :h, l) when x + l > 10 do
    make_pre_ship(10 - l, y, :h, l)
  end

  def make_pre_ship(x, y, :v, l) when y + l > 10 do
    make_pre_ship(x, 10 - l, :v, l)
  end

  def make_pre_ship(x, y, p, l) do
    Board.ship_opts_to_indexes(x, y, p, l)
  end

  def append_pre_ship(list, pre_ship_blocks) do
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
end