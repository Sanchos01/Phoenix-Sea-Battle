defmodule PhoenixSeaBattle.BoardTest do
  use ExUnit.Case
  alias PhoenixSeaBattle.Game.Board

  test "apply_ship/2 horizontal" do
    board = Board.new_board()
    opts = %{x: 1, y: 2, pos: :h, l: 4}
    assert {:ok, new_board} = Board.apply_ship(board, opts)

    assert [21, 22, 23, 24] ==
             new_board
             |> Enum.with_index()
             |> Enum.filter(&(elem(&1, 0) == :bs0))
             |> Enum.map(&elem(&1, 1))
  end

  test "apply_ship/2 vertical" do
    board = Board.new_board()
    opts = %{x: 1, y: 2, pos: :v, l: 4}
    assert {:ok, new_board} = Board.apply_ship(board, opts)

    assert [21, 31, 41, 51] ==
             new_board
             |> Enum.with_index()
             |> Enum.filter(&(elem(&1, 0) == :bs0))
             |> Enum.map(&elem(&1, 1))
  end

  test "drop_last/1" do
    board = Board.new_board()
    {:ok, board} = Board.apply_ship(board, %{x: 1, y: 2, pos: :h, l: 4})
    {:ok, board} = Board.apply_ship(board, %{x: 3, y: 4, pos: :v, l: 3})
    assert {:ok, new_board} = Board.drop_last(board)

    assert [bs0: 21, bs0: 22, bs0: 23, bs0: 24] ==
             new_board
             |> Enum.with_index()
             |> Enum.filter(&(elem(&1, 0) == :bs0))
  end

  test "prepare/1" do
    board = Board.new_board()
    {:ok, board} = Board.apply_ship(board, %{x: 1, y: 2, pos: :h, l: 4})
    {:ok, board} = Board.apply_ship(board, %{x: 3, y: 4, pos: :v, l: 3})
    {:ok, board} = Board.apply_ship(board, %{x: 0, y: 0, pos: :h, l: 3})
    {:ok, board} = Board.apply_ship(board, %{x: 4, y: 0, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 7, y: 0, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 0, y: 9, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 3, y: 9, pos: :h, l: 1})
    {:ok, board} = Board.apply_ship(board, %{x: 5, y: 9, pos: :h, l: 1})

    assert {:tb2, 1} = Board.prepare(board)
  end

  test "apply_shot/1" do
    board = Board.new_board()
    {:ok, board} = Board.apply_ship(board, %{x: 1, y: 2, pos: :h, l: 4})
    {:ok, board} = Board.apply_ship(board, %{x: 3, y: 4, pos: :v, l: 3})
    {:ok, board} = Board.apply_ship(board, %{x: 0, y: 0, pos: :h, l: 3})
    {:ok, board} = Board.apply_ship(board, %{x: 4, y: 0, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 7, y: 0, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 0, y: 9, pos: :h, l: 2})
    {:ok, board} = Board.apply_ship(board, %{x: 3, y: 9, pos: :h, l: 1})
    {:ok, board} = Board.apply_ship(board, %{x: 5, y: 9, pos: :h, l: 1})
    {:ok, board} = Board.apply_ship(board, %{x: 7, y: 9, pos: :h, l: 1})
    {:ok, board} = Board.apply_ship(board, %{x: 9, y: 9, pos: :h, l: 1})
    # hit
    assert {:ok, [_ | _], true} = Board.apply_shot(board, board, 21)
    # miss
    assert {:ok, [_ | _], false} = Board.apply_shot(board, board, 20)
    # kill
    assert {:ok, [_ | _], true} = Board.apply_shot(board, board, 99)
  end

  test "all_dead?/1" do
    board = Board.new_board()
    assert Board.all_dead?(board)
    {:ok, board} = Board.apply_ship(board, %{x: 1, y: 2, pos: :h, l: 4})
    refute Board.all_dead?(board)
  end
end
