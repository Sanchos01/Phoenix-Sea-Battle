defmodule PhoenixSeaBattleWeb.LobbyTest do
  use PhoenixSeaBattleWeb.ConnCase
  alias Phoenix.LiveViewTest
  alias PhoenixSeaBattleWeb.{Endpoint, Lobby, Presence}

  setup do
    user = insert_user()
    {:ok, view, _html} = LiveViewTest.mount(Endpoint, Lobby, session: %{user: user})
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
    html = LiveViewTest.render(view)
    assert html =~ "#{name}\n<br>\n<small>in lobby</small>"
    assert html =~ "user1\n<br>\n<small>in game</small>"
    assert html =~ "user2\n<br>\n<small>in game with user3</small>"
    assert html =~ "user4\n<br>\n<small>game ended</small>"
  end

  test "render messages and update", %{view: view} do
    msg = "lobby live view test"
    refute LiveViewTest.render(view) =~ msg
    LiveViewTest.render_submit(view, "insert_message", %{"chat-input" => msg})
    :timer.sleep(20)
    assert LiveViewTest.render(view) =~ "] Some User: #{msg}"
  end
end
