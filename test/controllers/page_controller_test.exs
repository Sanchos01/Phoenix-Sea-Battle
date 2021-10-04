defmodule PhoenixSeaBattle.PageControllerTest do
  use PhoenixSeaBattleWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "PhoenixSeaBattle · Phoenix Framework"
  end
end
