defmodule PhoenixSeaBattleWeb.Lobby do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger

  alias PhoenixSeaBattleWeb.{Endpoint, Presence, BoardView}
  alias PhoenixSeaBattle.{LobbyArchiver, User}
  alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes

  def mount(%{user: user}, socket) do
    Endpoint.subscribe("lobby")
    {:ok, msgs} = LobbyArchiver.subs()
    socket = assign(socket, messages: msgs, msg: nil)

    socket =
      case user do
        %User{name: name} ->
          {:ok, _} = Presence.track(self(), "lobby", name, %{state: 0})
          socket |> assign(user: user)

        _ ->
          socket
      end

    {:ok, fetch(socket)}
  end

  def render(assigns) do
    ~L"""
    <div id="chat" class="row chat container">
      <div class="column column-75">
        <div class="panel panel-default chat-room">
          <div class="panel-heading">
            Messages:
          </div>
          <div id="messages" class="panel-body panel-messages" style="text-overflow: clip">
            <%= for msg <- @messages do %>
              <div>
                <%= "[#{format_ts(msg.timestamp)}] #{msg.user}: #{msg.body}" %>
              </div>
            <% end %>
          </div>
        </div>
        <form phx-submit="insert_message">
          <input name="chat-input" type="text" class="form-control" value="<%= @msg %>"
                  placeholder="Type a message..." autocomplete="off">
        </form>
      </div>
      <div class="column">
        <div class="panel panel-default chat-room">
          <div class="panel-heading">
            Users Online:
          </div>
          <div id="userList" class="panel-body panel-users">
            <div>
              <%= for {user, %{metas: [meta | _]}} <- sort_users(@online_users) do %>
                <li class="users">
                <%= BoardView.render_user(user, meta) %>
                </li>
              <% end %>
            </div>
          </div>
        </div>
        <td class="text-right">
          <%= link "Start game", to: Routes.game_path(@socket, :index),
                class: "button button-default" %>
        </td>
      </div>
    </div>
    """
  end

  def handle_event("insert_message", %{"chat-input" => msg}, socket) when msg != "" do
    case socket.assigns do
      %{user: %User{name: username}} ->
        LobbyArchiver.new_msg(msg, username)
        {:noreply, assign(socket, msg: msg)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_info({:update, messages}, socket) do
    {:noreply, assign(socket, messages: messages, msg: nil)}
  end

  def handle_info(%Broadcast{event: event}, socket)
      when event in ~w(presence_diff change_state) do
    {:noreply, fetch(socket)}
  end

  defp format_ts(ts) do
    ts |> DateTime.from_unix!() |> Calendar.Strftime.strftime!("%r")
  end

  defp fetch(socket) do
    assign(socket, online_users: Presence.list("lobby"))
  end

  def sort_users(users) do
    Enum.sort(users, fn
      {_, %{metas: [%{state: 1} | _]}}, _ -> true
      _, {_, %{metas: [%{state: 1} | _]}} -> false
      {_, %{metas: [%{state: s1} | _]}}, {_, %{metas: [%{state: s2} | _]}} -> s1 < s2
    end)
  end
end
