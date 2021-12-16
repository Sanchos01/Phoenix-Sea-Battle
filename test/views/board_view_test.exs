defmodule PhoenixSeaBattleWeb.BoardViewTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true
  alias PhoenixSeaBattleWeb.BoardView
  import Phoenix.LiveViewTest

  test "render_user/2" do
    assert render_user_view(%{user: "asd", meta: %{state: 0}}) =~ "in lobby"
    assert render_user_view(%{user: "asd", meta: %{state: 1, game_id: "1234"}}) =~ "in game"
    assert render_user_view(%{user: "asd", meta: %{state: 2, with: "qwe"}}) =~ "in game with qwe"
    assert render_user_view(%{user: "asd", meta: %{state: 3}}) =~ "game ended"
    assert_raise FunctionClauseError, fn -> BoardView.render_user(%{user: "asd", meta: %{}}) end
  end

  defp render_user_view(assigns) do
    render_component(&BoardView.render_user/1, assigns)
  end
end
