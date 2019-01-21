defmodule PhoenixSeaBattle.Game.Board do
  @columns for x <- ?a..?j, do: "#{<<x>>}"
  @lines for x <- 0..9, do: "#{x}"
  defstruct Enum.map(@columns, & {:"#{&1}", Enum.take(Stream.cycle([0]), 10)})

  def new(body) do
    with board = %__MODULE__{} <- board_in_struct(body),
         true                  <- valid?(board)
    do
      board
    else
      _ -> {:error, :invalid_board}
    end
  end

  def valid?(board) do
    all_fields =
      board
      |> Map.from_struct()
      |> Map.values()
      |> List.flatten()
    uniqs = Enum.uniq(all_fields)
    only_ships = Enum.reduce(all_fields, [], fn
      0, acc    -> acc
      some, acc -> [some|acc]
    end)
    (length(uniqs) == 11) && (length(only_ships) == 20)
  end

  defp board_in_struct(board), do: board_in_struct(board, 1, %__MODULE__{})
  defp board_in_struct([], _num, struct), do: struct
  defp board_in_struct([ship|rest], num, struct) do
    with new_struct = %__MODULE__{} <- ship_in_struct(ship, num, struct) do
      board_in_struct(rest, num + 1, new_struct)
    end
  end

  defp ship_in_struct([], _num, struct), do: struct
  defp ship_in_struct([point|rest], num, struct) do
    with <<column::binary-size(1), ":", line::binary>> <- point,
         true <- column in @columns,
         true <- line in @lines
    do
      column = String.to_existing_atom(column)
      line = String.to_integer(line)
      new_struct = Map.update!(struct, column, &(List.update_at(&1, line, fn _ -> num end)))
      ship_in_struct(rest, num, new_struct)
    else
      _ -> {:error, :invalid_board}
    end
  end
end
