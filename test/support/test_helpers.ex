defmodule PhoenixSeaBattle.TestHelpers do
  alias PhoenixSeaBattle.Repo

  def insert_user(attrs \\ %{}) do
    changes = Map.merge(%{
      name: "Some User",
      username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
      password: "supersecret",
    }, attrs)

    %PhoenixSeaBattle.User{}
    |> PhoenixSeaBattle.User.registration_changeset(changes)
    |> Repo.insert!()
  end
end