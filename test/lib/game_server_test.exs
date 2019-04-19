defmodule PhoenixSeaBattle.GameServerTest do
  use PhoenixSeaBattleWeb.ModelCase, async: true
  alias PhoenixSeaBattle.GameServer
  alias PhoenixSeaBattle.Game.Supervisor, as: GameSupervisor

  setup do
    <<id::binary-8, _::binary>> = Ecto.UUID.generate()
    {:ok, pid} = GameSupervisor.new_game(id)
    %{pid: pid, id: id}
  end

  test "terminate/2", %{id: id, pid: pid} do
    user_1 = insert_user(%{name: "game_test1", username: "user_game_test1", password: "secret"})
    user_2 = insert_user(%{name: "game_test2", username: "user_game_test2", password: "secret"})
    ref = Process.monitor(pid)
    {:ok, :admin} = GameServer.add_user(pid, user_1)
    {:ok, :opponent} = GameServer.add_user(pid, user_2)
    {:ok, _} = GameServer.get(pid, user_1)
    {:ok, _} = GameServer.get(pid, user_2)
    :sys.terminate(pid, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid, :kill}, 100
    assert_receive :retry_connect, 100
    assert_receive :retry_connect, 100
    :timer.sleep(100)
    assert "#{id}" |> GameSupervisor.via_tuple() |> GenServer.whereis() |> is_pid()
  end

  test "get_board_and_shots/2 error case", %{pid: pid} do
    assert :error == GameServer.get_board_and_shots(pid, :some)
  end
end
