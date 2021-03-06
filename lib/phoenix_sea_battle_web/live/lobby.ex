defmodule PhoenixSeaBattleWeb.Lobby do
  use Phoenix.LiveView
  use Phoenix.HTML
  require Logger

  alias PhoenixSeaBattleWeb.{Endpoint, Presence, BoardView}
  alias PhoenixSeaBattle.{LobbyArchiver, User}
  alias Phoenix.Socket.Broadcast
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes

  def mount(%{user: user}, socket) do
    with true <- connected?(socket) do
      :ok = Endpoint.subscribe("lobby")
      {:ok, msgs} = LobbyArchiver.subs()
      socket = assign(socket, messages: msgs)

      case user do
        %User{name: name} ->
          {:ok, _} = Presence.track(self(), "lobby", name, %{state: 0})
          {:ok, socket |> assign(user: user) |> fetch()}

        _ ->
          {:ok, fetch(socket)}
      end
    else
      false -> {:ok, socket |> assign(messages: [], online_users: [])}
    end
  end

  def render(assigns) do
    ~L"""
    <div id="chat" class="chat container">
      <div>
        <div class="panel panel-default">
          <div class="panel-heading">
            Messages:
          </div>
          <div id="messages" class="panel-body">
            <%= for msg <- @messages do %>
              <div>
                <%= "[#{format_ts(msg.timestamp)}] #{msg.user}: #{msg.body}" %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <div>
        <div class="panel panel-default">
          <div class="panel-heading">
            Users Online:
          </div>
          <div id="userList" class="panel-body">
            <div>
              <%= for {user, %{metas: [meta | _]}} <- sort_users(@online_users) do %>
                <li class="users">
                <%= BoardView.render_user(user, meta) %>
                </li>
              <% end %>
            </div>
          </div>
        </div>
      </div>
      <div>
        <form phx-submit="insert_message">
          <input name="chat-input" type="text" class="form-control" value=""
                  maxlength="100" placeholder="Type a message..." autocomplete="off">
        </form>
      </div>
      <div>
        <td class="text-right">
          <%= link "Start game", to: Routes.game_path(@socket, :index),
                class: "button button-default" %>
        </td>
      </div>
    </div>
    """
  end

  def handle_event("insert_message", %{"chat-input" => msg}, socket) when msg != "" do
    with msg when is_binary(msg) and msg != "" <- HtmlSanitizeEx.strip_tags(msg),
         %{user: %User{name: username}} <- socket.assigns do
      LobbyArchiver.new_msg(msg, username)
    else
      _ -> :ok
    end

    {:noreply, socket}
  end

  def handle_event("insert_message", _, socket) do
    {:noreply, socket}
  end

  def handle_info({:update, messages}, socket) do
    {:noreply, assign(socket, messages: messages)}
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
