defmodule PhoenixSeaBattleWeb.UserSocket do
  use Phoenix.Socket
  require Logger
  import Ecto.Query, warn: false
  alias Phoenix.Token
  alias PhoenixSeaBattle.{User, Repo}

  ## Channels
  channel "room:lobby", PhoenixSeaBattleWeb.RoomChannel
  channel "game:*", PhoenixSeaBattleWeb.GameChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @max_age 2 * 7 * 24 * 60 * 60

  def connect(%{"token" => token}, socket) do
    with {:ok, user_id} <- Token.verify(socket, "user socket", token, max_age: @max_age),
         q = (from u in User, where: u.id == ^user_id, select: u.username),
         username when is_binary(username) <- Repo.one(q)
    do
      {:ok, socket |> assign(:user_id, user_id) |> assign(:user, username)}
    else
      _ -> :error
    end
  end
  def connect(_params, _socket), do: :error
  def id(%{assigns: %{user_id: user_id}}), do: "users_socket:#{user_id}"

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PhoenixSeaBattle.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  # def id(_socket), do: nil
end
