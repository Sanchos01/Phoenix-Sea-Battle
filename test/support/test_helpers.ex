defmodule PhoenixSeaBattleWeb.TestHelpers do
  alias PhoenixSeaBattle.Repo

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "Some User",
      username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      password: "supersecret",
    }, attrs)

    %PhoenixSeaBattleWeb.User{}
    |> PhoenixSeaBattleWeb.User.registration_changeset(changes)
    |> Repo.insert!()
  end
end