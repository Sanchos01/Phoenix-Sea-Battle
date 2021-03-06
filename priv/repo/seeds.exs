# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PhoenixSeaBattle.Repo.insert!(%PhoenixSeaBattle.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias PhoenixSeaBattle.Repo
alias PhoenixSeaBattle.User

for user <- ~w(foo bar baz) do
  with nil <- Repo.get_by(User, username: user <> "123"),
       %{name: name, username: username, password_hash: pass_hash} <-
         User.registration_changeset(%User{}, %{name: user, username: user <> "123", password: "123 super secret"}).changes,
  do: Repo.insert!(%User{name: name, username: username, password_hash: pass_hash})
end