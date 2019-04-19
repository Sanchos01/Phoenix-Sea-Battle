defmodule PhoenixSeaBattleWeb.Game.InitialEventHandle do
  require Logger
  alias PhoenixSeaBattle.Game

  def apply_key(_key, %{assigns: %{render_opts: %{ready: true}}}) do
    :ok
  end

  def apply_key("ArrowLeft", %{assigns: %{render_opts: render_opts = %{x: x}}}) when x > 0 do
    new_render_opts = %{render_opts | x: x - 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key("ArrowRight", %{assigns: %{render_opts: render_opts = %{x: x, l: l, pos: :h}}})
      when x + l < 10 do
    new_render_opts = %{render_opts | x: x + 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key("ArrowRight", %{assigns: %{render_opts: render_opts = %{x: x, pos: :v}}})
      when x < 9 do
    new_render_opts = %{render_opts | x: x + 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key("ArrowUp", %{assigns: %{render_opts: render_opts = %{y: y}}}) when y > 0 do
    new_render_opts = %{render_opts | y: y - 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key("ArrowDown", %{assigns: %{render_opts: render_opts = %{y: y, pos: :v, l: l}}})
      when y + l < 10 do
    new_render_opts = %{render_opts | y: y + 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key("ArrowDown", %{assigns: %{render_opts: render_opts = %{y: y, pos: :h}}})
      when y < 9 do
    new_render_opts = %{render_opts | y: y + 1}
    {:ok, render_opts: new_render_opts}
  end

  def apply_key(k, %{assigns: %{render_opts: render_opts}}) when k in ~w(- _) do
    new_render_opts =
      case render_opts do
        %{pos: :h, y: y, l: l} ->
          if l + y > 10 do
            %{render_opts | pos: :v, y: 10 - l}
          else
            %{render_opts | pos: :v}
          end

        %{pos: :v, x: x, l: l} ->
          if l + x > 10 do
            %{render_opts | pos: :h, x: 10 - l}
          else
            %{render_opts | pos: :h}
          end
      end

    {:ok, render_opts: new_render_opts}
  end

  def apply_key(k, %{assigns: assigns}) when k in ~w(+ =) do
    Game.apply_ship(assigns.pid, assigns.user.id, assigns.render_opts)
    :ok
  end

  def apply_key(_key, _socket) do
    :ok
  end

  def apply_event("drop_last", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_last(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("drop_all", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_all(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("ready", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.ready(socket.assigns.pid, socket.assigns.user.id)
  end

  def apply_event("unready", _key, socket = %{assigns: %{game_state: :ready}}) do
    Game.unready(socket.assigns.pid, socket.assigns.user.id)
  end
end
