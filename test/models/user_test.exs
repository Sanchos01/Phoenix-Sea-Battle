defmodule PhoenixSeaBattle.UserTest do
  use PhoenixSeaBattleWeb.ModelCase, async: true
  alias PhoenixSeaBattle.User
  alias Comeonin.Bcrypt

  @valid_attrs %{name: "A User", username: "eva", password: "secret"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset does not accept long usernames" do
    attrs = Map.put(@valid_attrs, :username, String.duplicate("a", 30))
    assert username: {"should be at most %{count} character(s)", [count: 20, validation: :length, max: 20]} in
      errors_on(%User{}, attrs)
  end

  test "registration_changeset password must be at least 6 chars or long" do
    attrs = Map.put(@valid_attrs, :password, "12345")
    changeset = User.registration_changeset(%User{}, attrs)
    assert password: {"should be at least %{count} character(s)", [count: 6, validation: :length, min: 6]} in
      changeset.errors
  end

  test "registration_changeset with valid attributes hashes password" do
    attrs = Map.put(@valid_attrs, :password, "123456")
    changeset = User.registration_changeset(%User{}, attrs)
    %{password: pass, password_hash: pass_hash} = changeset.changes

    assert changeset.valid?
    assert pass_hash
    assert Bcrypt.checkpw(pass, pass_hash)
  end
end
