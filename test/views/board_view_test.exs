defmodule PhoenixSeaBattleWeb.BoardViewTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias PhoenixSeaBattleWeb.BoardView

  test "render_user/2" do
    assert safe_to_string(BoardView.render_user("asd", %{state: 0})) =~ "in lobby"
    assert safe_to_string(BoardView.render_user("asd", %{state: 1, game_id: "1234"})) =~ "in game"

    assert safe_to_string(BoardView.render_user("asd", %{state: 2, with: "qwe"})) =~
             "in game with qwe"

    assert safe_to_string(BoardView.render_user("asd", %{state: 3})) =~ "game ended"
    assert_raise FunctionClauseError, fn -> BoardView.render_user("asd", %{}) end
  end
end
