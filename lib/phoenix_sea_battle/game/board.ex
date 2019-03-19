defmodule PhoenixSeaBattle.Game.Board do
  @columns for x <- ?a..?j, do: "#{<<x>>}"
  @lines for x <- 0..9, do: "#{x}"
  # 4 - battleship - bs0
  # 3 - cruiser - c{0-1}
  # 2 - destroyer - d{0-2}
  # 1 - torpedo boat - tb{0-3}
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a
  @ships_length [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]
  @ships Enum.zip(@marks, @ships_length)

  def new(), do: :array.new(100, default: 0)

  def prepare(board) do
    ships = all_ships(board)
    true = valid?(ships, board)
    anyone_missed?(ships)
  end

  defp all_ships(board) do
    :array.foldr(fn
      _index, 0, acc ->
        acc
      index, type, acc ->
        indexes = acc[type] || []
        Map.put(acc, type, [index | indexes])
    end, %{}, board)
  end

  defp valid?(ships, board) do
    Enum.reduce_while(ships, true, fn
      {:bt0, [i1, i2, i3, i4] = indexes}, acc ->
        with true <- vertical?(indexes) or horizontal?(indexes),
             true <- all_nearest_empty?(indexes, board)
        do
          {:cont, acc}
        else
          _ -> {:halt, false}
        end
      _, _ ->
        {:halt, false}
    end)
  end

  defp vertical?([_]), do: true
  defp vertical?([i1 | [i2 | _] = rest]) do
    i1 + 10 == i2 and vertical?(rest)
  end

  defp horizontal?([_]), do: true
  defp horizontal?([i1 | [i2 | _] = rest]) do
    i1 + 1 == i2 and horizontal?(rest)
  end

  defp all_nearest_empty?(indexes, board) do
    Enum.reduce_while(indexes, true, fn i, acc ->
      if nearest_empty?(i, board, indexes), do: {:cont, acc}, else: {:halt, false}
    end)
  end

  defp nearest_empty?(index, board, indexes) do
    top? = index < 10
    bottom? = index > 89
    left? = rem(index, 10)
    right? = rem(index + 1, 10)
    (left? or top? or :array.get(index - 11, board) == 0) and
    (top? or (index - 10 in indexes) or :array.get(index - 10, board) == 0) and
    (right? or top? or :array.get(index - 9, board) == 0) and
    (left? or (index - 1 in indexes) or :array.get(index - 1, board) == 0) and
    (right? or (index + 1 in indexes) or :array.get(index + 1, board) == 0) and
    (left? or bottom? or :array.get(index + 9, board) == 0) and
    (bottom? or (index + 10 in indexes) or :array.get(index + 10, board) == 0) and
    (right? or bottom? or :array.get(index + 11, board) == 0)
  end

  defp anyone_missed?(ships) do
    Enum.reduce_while(@marks, :ok, fn mark, acc ->
      case ships[mark] do
        nil -> {:halt, @ships[mark]}
        _ -> {:cont, acc}
      end
    end)
  end
end
