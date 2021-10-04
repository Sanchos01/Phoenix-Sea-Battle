defmodule PhoenixSeaBattleWeb.Game.InitialEventHandle do
  require Logger
  alias PhoenixSeaBattle.GameServer

  def apply_event("drop_last", _key, socket = %{assigns: %{game_state: :initial}}) do
    GameServer.drop_last(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("drop_all", _key, socket = %{assigns: %{game_state: :initial}}) do
    GameServer.drop_all(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("ready", _key, socket = %{assigns: %{game_state: :initial}}) do
    GameServer.ready(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("unready", _key, socket = %{assigns: %{game_state: :ready}}) do
    GameServer.unready(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("place", _params, %{assigns: %{game_state: :initial} = assigns}) do
    GameServer.apply_ship(assigns.pid, assigns.user.id, assigns.render_opts)
  end

  def apply_event("place", _params, _socket), do: :ok

  def apply_event("rotate", _params, %{
        assigns: %{render_opts: render_opts = %{x: x, y: y, l: l}, game_state: :initial}
      }) do
    new_render_opts =
      case render_opts.pos do
        :h ->
          y = if y + l > 10, do: 10 - l, else: y
          %{render_opts | pos: :v, y: y}

        :v ->
          x = if x + l > 10, do: 10 - l, else: x
          %{render_opts | pos: :h, x: x}
      end

    {:ok, render_opts: new_render_opts}
  end

  def apply_event("rotate", _params, _socket) do
    :ok
  end

  def apply_event("mouseover", %{"index" => index_string}, %{
        assigns: %{render_opts: %{ready: false} = render_opts, game_state: :initial}
      }) do
    index = String.to_integer(index_string)

    new_render_opts =
      case render_opts do
        %{pos: :h, l: l} ->
          y = div(index, 10)
          new_x = rem(index, 10)
          x = if l + new_x > 10, do: 10 - l, else: new_x
          %{render_opts | x: x, y: y}

        %{pos: :v, l: l} ->
          x = rem(index, 10)
          new_y = div(index, 10)
          y = if l + new_y > 10, do: 10 - l, else: new_y
          %{render_opts | x: x, y: y}
      end

    {:ok, render_opts: new_render_opts}
  end

  def apply_event("mouseover", _params, _socket), do: :ok
end
