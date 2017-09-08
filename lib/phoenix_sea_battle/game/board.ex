defmodule PhoenixSeaBattle.Game.Board do
  use ExActor.GenServer
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
    initial_state(%{board: %__MODULE__{}, id: opts[:id]})
  end

  defcall new(board), state: state do
    new_board = board_in_struct(board)
    set_and_reply(%{state | board: new_board}, :ok)
  end

  defp board_in_struct(board), do: board_in_struct(board, 1, %__MODULE__{})
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

  defcall valid?(), state: %{board: board} do
    board = Map.drop(board, [:__struct__])
    uniqs = Map.values(board)
            |> List.flatten()
            |> Enum.uniq()
    only_ships = Map.values(board)
                  |> List.flatten
                  |> Enum.reduce([], fn 0, acc -> acc
                                     some, acc -> [some|acc] end)
    reply((length(uniqs) == 11) && (length(only_ships) == 20))
  end
end