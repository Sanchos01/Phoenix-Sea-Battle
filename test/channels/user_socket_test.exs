defmodule PhoenixSeaBattle.Channels.UserSocketTest do
  use PhoenixSeaBattleWeb.ChannelCase, async: true
  alias PhoenixSeaBattleWeb.UserSocket
  alias Phoenix.Token

  setup config do
    if username = config[:login_as] do
      user = insert_user(%{username: username, password: "secret"})
      {:ok, user: user}
    else
      :ok
    end
  end

  @tag login_as: "max123"
  test "socket authentication with valid token", %{user: user} do
    token = Token.sign(@endpoint, "user socket", user.id)
    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.user == "max123"
  end

  test "socket authentication with invalid token" do
    assert :error = connect(UserSocket, %{"token" => "1313"})
    assert :error = connect(UserSocket, %{})
  end
end
