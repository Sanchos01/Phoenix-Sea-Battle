defmodule PhoenixSeaBattle.User do
  use PhoenixSeaBattleWeb, :model
  alias Comeonin.Bcrypt

  schema "users" do
    field(:name, :string)
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)

    timestamps()
  end

  @format ~r/^[a-zA-Z0-9_]+$/

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :username])
    |> validate_required([:username, :name])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:name, min: 3, max: 20)
    |> validate_format(:username, @format, message: "only letters, numbers, and underscores")
    |> validate_format(:name, @format, message: "only letters, numbers, and underscores")
    |> unique_constraint(:username)
    |> unique_constraint(:name)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, [:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hashpwsalt(pass))

      _ ->
        changeset
    end
  end
end
