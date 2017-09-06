defmodule PhoenixSeaBattle.Game.Board do
  use ExActor.GenServer
  alias __MODULE__
  require Logger

  defstruct [
    a: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    b: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    c: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    d: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    e: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    f: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    g: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    h: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    i: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    j: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  ]

  defstart start_link(_, opts) do
    initial_state(%{board: %Board{}, id: opts[:id]})
  end

  defcall ready(board), state: state do
    new_board = board_in_struct(board)
    set_and_reply(%{state | board: new_board}, :ok)
  end

  defp board_in_struct(board), do: board_in_struct(board, 1, %Board{})
  defp board_in_struct([], _num, struct), do: struct
  defp board_in_struct([ship|rest], num, struct) do
    board_in_struct(rest, num + 1, ship_in_struct(ship, num, struct))
  end

  defp ship_in_struct([], _num, struct), do: struct
  defp ship_in_struct([point|rest], num, struct) do
    <<column::binary-size(1), ":", line::binary>> = point
    column = String.to_atom(column)
    line = String.to_integer(line)
    new_struct = Map.update!(struct, column, &(List.update_at(&1, line, fn _ -> num end)))
    ship_in_struct(rest, num, new_struct)
  end
end