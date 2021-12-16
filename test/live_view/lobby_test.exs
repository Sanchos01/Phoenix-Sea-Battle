defmodule PhoenixSeaBattleWeb.LobbyTest do
  use PhoenixSeaBattleWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias PhoenixSeaBattleWeb.Presence
  alias PhoenixSeaBattleWeb.Live.Lobby

  setup %{conn: conn} do
    user = insert_user()
    {:ok, view, _html} = live_isolated(conn, Lobby, session: %{"user" => user})
    {:ok, %{view: view, user: user}}
  end

  defp track_and_sleep(user, meta) do
    Presence.track(self(), "lobby", user, meta)
    :timer.sleep(100)
  end

  test "render user list (client online)", %{view: view, user: %{name: name}} do
    Task.async(fn -> track_and_sleep("user1", %{state: 1, game_id: "asdqwe"}) end)
    Task.async(fn -> track_and_sleep("user2", %{state: 2, with: "user3"}) end)
    Task.async(fn -> track_and_sleep("user4", %{state: 3}) end)
    :timer.sleep(20)
    html = render(view)
    assert html =~ "#{name}\n<br/><small>in lobby</small>"
    assert html =~ "user1\n<br/><small>in game</small>"
    assert html =~ "user2\n<br/><small>in game with user3</small>"
    assert html =~ "user4\n<br/><small>game ended</small>"
  end

  test "render messages and update", %{view: view} do
    msg = "lobby live view test"
    refute render(view) =~ msg
    render_submit(view, "insert_message", %{"chat-input" => msg})
    :timer.sleep(20)
    assert render(view) =~ "] SomeUser: #{msg}"
  end
end
