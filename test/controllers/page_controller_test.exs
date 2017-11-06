defmodule PhoenixSeaBattle.PageControllerTest do
  use PhoenixSeaBattleWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Hello PhoenixSeaBattle!"
  end
end
