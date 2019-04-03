defmodule PhoenixSeaBattleWeb.TestHelpers do
  alias PhoenixSeaBattle.{User, Repo}

  def insert_user(attrs \\ %{}) do
    changes =
      Map.merge(
        %{
          name: "SomeUser",
          username: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}",
          password: "supersecret"
        },
        attrs
      )

    %User{}
    |> User.registration_changeset(changes)
    |> Repo.insert!()
  end
end
