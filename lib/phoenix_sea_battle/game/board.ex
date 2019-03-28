defmodule PhoenixSeaBattle.Game.Board do
  @default_board [0] |> Stream.cycle() |> Enum.take(100)
  @default_shots [nil] |> Stream.cycle() |> Enum.take(100)

  # 4 - battleship - bs0
  # 3 - cruiser - c{0-1}
  # 2 - destroyer - d{0-2}
  # 1 - torpedo boat - tb{0-3}
  @marks ~w(bs0 c0 c1 d0 d1 d2 tb0 tb1 tb2 tb3)a
  @ships_length [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]
  @ships Enum.zip(@marks, @ships_length)

  def new_board(), do: @default_board
  def new_shots(), do: @default_shots

  def prepare(board) do
    ships = all_ships(board)
    true = valid?(ships, board)
    anyone_missed?(ships)
  end

  def apply_ship(board, %{x: x, y: y, pos: p, l: l}) do
    pre_ship_blocks = ship_opts_to_indexes(x, y, p, l)

    with :ok <- check_cross(board, pre_ship_blocks),
         true <- all_nearest_empty?(pre_ship_blocks, board) || {:error, :nearest} do
      apply_pre_blocks(board, pre_ship_blocks)
    end
  end

  def ship_opts_to_indexes(x, y, :h, l) do
    for add <- 0..(l - 1) do
      x + add + 10 * y
    end
  end

  def ship_opts_to_indexes(x, y, :v, l) do
    for add <- 0..(l - 1) do
      x + 10 * (y + add)
    end
  end

  def near_indexes(index) do
    top? = index < 10
    bottom? = index > 89
    left? = rem(index, 10) == 0
    right? = rem(index + 1, 10) == 0

    (return_index(left?, top?, index - 11) ++
       return_index(top?, index - 10) ++
       return_index(right?, top?, index - 9) ++
       return_index(left?, index - 1) ++
       return_index(right?, index + 1) ++
       return_index(left?, bottom?, index + 9) ++
       return_index(bottom?, index + 10) ++
       return_index(right?, bottom?, index + 11))
    |> Enum.reject(&is_nil/1)
  end

  def drop_last(board) do
    case board |> all_ships() |> Map.keys() do
      [_ | _] = ships ->
        last =
          Enum.reduce_while(@marks, ships, fn
            _, [last] -> {:halt, last}
            m, acc -> {:cont, acc -- [m]}
          end)

        new_board =
          Enum.map(board, fn
            ^last -> 0
            x -> x
          end)

        {:ok, new_board}

      [] ->
        {:error, :no_ships}
    end
  end

  defp return_index(boolean1, boolean2 \\ false, index)
  defp return_index(false, false, index), do: [index]
  defp return_index(_, _, _), do: [nil]

  defp apply_pre_blocks(board, indexes) do
    ships = all_ships(board)
    {mark, _} = anyone_missed?(ships)

    new_board =
      Enum.reduce(indexes, board, fn i, acc ->
        List.replace_at(acc, i, mark)
      end)

    {:ok, new_board}
  end

  defp all_ships(board) do
    board
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn
      {0, _}, acc ->
        acc

      {type, index}, acc ->
        indexes = acc[type] || []
        Map.put(acc, type, indexes ++ [index])
    end)
  end

  defp valid?(ships, board) do
    Enum.reduce_while(ships, true, fn
      {:bs0, [_, _, _, _] = indexes}, acc ->
        validate(indexes, acc, board)

      {k, [_, _, _] = indexes}, acc when k in ~w(c0 c1)a ->
        validate(indexes, acc, board)

      {k, [_, _] = indexes}, acc when k in ~w(d0 d1 d2)a ->
        validate(indexes, acc, board)

      {k, [_] = indexes}, acc when k in ~w(tb0 tb1 tb2 tb3)a ->
        validate(indexes, acc, board)

      _, _ ->
        {:halt, false}
    end)
  end

  defp validate(indexes, acc, board) do
    with true <- vertical?(indexes) or horizontal?(indexes),
         true <- all_nearest_empty?(indexes, board) do
      {:cont, acc}
    else
      _ -> {:halt, false}
    end
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
    index
    |> near_indexes()
    |> Enum.reduce_while(true, fn i, acc ->
      if i in indexes or Enum.at(board, i) == 0 do
        {:cont, acc}
      else
        {:halt, false}
      end
    end)
  end

  defp anyone_missed?(ships) do
    Enum.reduce_while(@marks, :ok, fn mark, acc ->
      case ships[mark] do
        nil -> {:halt, {mark, @ships[mark]}}
        _ -> {:cont, acc}
      end
    end)
  end

  defp check_cross(board, indexes) do
    Enum.reduce_while(indexes, :ok, fn index, acc ->
      if Enum.at(board, index) == 0 do
        {:cont, acc}
      else
        {:halt, {:error, :cross}}
      end
    end)
  end
end
