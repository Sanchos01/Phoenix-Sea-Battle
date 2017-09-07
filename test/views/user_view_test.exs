defmodule PhoenixSeaBattle.UserViewTest do
  alias PhoenixSeaBattle.UserView
  use PhoenixSeaBattle.ConnCase, async: true
  # import Phoenix.View

  setup config do
    if username = config.login_as do
      user = insert_user(%{username: username, password: "secret"})
      {:ok, %{user: user, id: user.id}}
    else
      :ok
    end
  end

  @tag login_as: "max123"
  test "render user.json", %{user: user, id: id} do
    assert UserView.render("user.json", %{user: user}) == %{username: "max123", id: id}
  end
end
