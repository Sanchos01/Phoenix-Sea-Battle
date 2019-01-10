defmodule PhoenixSeaBattle.Game.Board do
  use GenServer
  require Logger

  @columns for x <- ?a..?j, do: :"#{<<x>>}"

  defstruct Enum.map(@columns, & {&1, Enum.take(Stream.cycle([0]), 10)})

  def start_link([id: id]) do
    GenServer.start_link(__MODULE__, [id: id])
  end

  def init([id: id]) do
    {:ok, %{board: %__MODULE__{}, id: id}}
  end

  def new(pid, board), do: GenServer.call(pid, {:new, board})
  def valid?(pid), do: GenServer.call(pid, :valid?)

  # new
  def handle_call({:new, board}, _from, state) do
    new_board = board_in_struct(board)
    {:reply, :ok, %{state | board: new_board}}
  end

  # valid?
  def handle_call(:valid?, _from, state = %{board: board}) do
    board = Map.drop(board, [:__struct__])
    uniqs = Map.values(board)
            |> List.flatten()
            |> Enum.uniq()
    only_ships = Map.values(board)
                  |> List.flatten
                  |> Enum.reduce([], fn 0, acc -> acc
                                     some, acc -> [some|acc] end)
    {:reply, (length(uniqs) == 11) && (length(only_ships) == 20), state}
  end

  defp board_in_struct(board), do: board_in_struct(board, 1, %__MODULE__{})
  defp board_in_struct([], _num, struct), do: struct
  defp board_in_struct([ship|rest], num, struct) do
    board_in_struct(rest, num + 1, ship_in_struct(ship, num, struct))
  end

  defp ship_in_struct([], _num, struct), do: struct
  defp ship_in_struct([point|rest], num, struct) do
    <<column::binary-size(1), ":", line::binary>> = point
    column = String.to_existing_atom(column)
    line = String.to_integer(line)
    new_struct = Map.update!(struct, column, &(List.update_at(&1, line, fn _ -> num end)))
    ship_in_struct(rest, num, new_struct)
  end
end