defmodule PhoenixSeaBattleWeb.UserView do
  use PhoenixSeaBattleWeb, :view
  alias PhoenixSeaBattle.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, username: user.username}
  end
end
