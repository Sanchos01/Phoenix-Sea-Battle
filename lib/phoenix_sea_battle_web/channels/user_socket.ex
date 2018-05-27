defmodule PhoenixSeaBattleWeb.UserSocket do
  require Logger
  use Phoenix.Socket
  alias PhoenixSeaBattle.Repo

  ## Channels
  channel "room:lobby", PhoenixSeaBattleWeb.RoomChannel
  channel "game:*", PhoenixSeaBattleWeb.GameChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    transport_log: :debug
  # transport :longpoll, Phoenix.Transports.LongPoll

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
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user_id} ->
        %{username: username} = Repo.get(PhoenixSeaBattleWeb.User, user_id)
        {:ok, socket |> assign(:user_id, user_id) |> assign(:user, username)}
      {:error, reason} -> (Logger.warn("user unauthorized #{inspect reason}"); :error)
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
