defmodule PhoenixSeaBattleWeb.Game.InitialEventHandle do
  use Phoenix.LiveView
  require Logger
  alias PhoenixSeaBattle.Game

  def render(assigns) do
    ~L"""
    """
  end

  def apply_key(_key, socket = %{assigns: %{render_opts: %{ready: true}}}) do
    {:noreply, socket}
  end

  def apply_key("ArrowLeft", socket) do
    render_opts = socket.assigns.render_opts

    if can_decrease_x?(render_opts) do
      new_render_opts = %{render_opts | x: render_opts.x - 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowRight", socket) do
    render_opts = socket.assigns.render_opts

    if can_increase_x?(render_opts) do
      new_render_opts = %{render_opts | x: render_opts.x + 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowUp", socket) do
    render_opts = socket.assigns.render_opts

    if can_decrease_y?(render_opts) do
      new_render_opts = %{render_opts | y: render_opts.y - 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key("ArrowDown", socket) do
    render_opts = socket.assigns.render_opts

    if can_increase_y?(render_opts) do
      new_render_opts = %{render_opts | y: render_opts.y + 1}
      {:noreply, assign(socket, render_opts: new_render_opts)}
    else
      {:noreply, socket}
    end
  end

  def apply_key(k, socket) when k in ~w(- _) do
    render_opts = socket.assigns.render_opts

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

    {:noreply, assign(socket, render_opts: new_render_opts)}
  end

  def apply_key(k, socket = %{assigns: assigns}) when k in ~w(+ =) do
    Game.apply_ship(assigns.pid, assigns.user.id, assigns.render_opts)
    {:noreply, socket}
  end

  def apply_key(_key, socket) do
    {:noreply, socket}
  end

  def apply_event("drop_last", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_last(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("drop_all", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.drop_all(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("ready", _key, socket = %{assigns: %{game_state: :initial}}) do
    Game.ready(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event("unready", _key, socket = %{assigns: %{game_state: :ready}}) do
    Game.unready(socket.assigns.pid, socket.assigns.user.id)
    {:noreply, socket}
  end

  def apply_event(event, _key, socket) do
    Logger.warn("unhandled event: #{inspect(event)} ; #{inspect(socket)}")
    {:noreply, socket}
  end

  defp can_decrease_x?(%{x: x}) do
    x > 0
  end

  defp can_increase_x?(%{x: x, pos: pos, l: l}) do
    case pos do
      :h -> x + l < 10
      :v -> x < 9
    end
  end

  defp can_decrease_y?(%{y: y}) do
    y > 0
  end

  defp can_increase_y?(%{y: y, pos: pos, l: l}) do
    case pos do
      :v -> y + l < 10
      :h -> y < 9
    end
  end
end
