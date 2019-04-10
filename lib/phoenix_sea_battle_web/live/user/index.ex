defmodule PhoenixSeaBattleWeb.UserLive.Index do
  use Phoenix.LiveView
  use Phoenix.HTML
  import Ecto.Query, only: [from: 2, limit: 3, offset: 3]

  alias PhoenixSeaBattle.{User, Repo}
  alias PhoenixSeaBattleWeb.UserView

  @page_size 2
  @pre_query from(u in User, order_by: u.id, select: map(u, [:id, :name]))

  def mount(_session, socket) do
    page_size = @page_size
    total = maybe_update_total(true, 0)
    {:ok, assign(socket, page: 1, page_size: page_size, total: total, update?: false)}
  end

  def render(assigns) do
    ~L"""
      <%= if @page > 1 do %>
        <button phx-click="prev_page" class="button">Prev</button>
      <% else %>
        <button class="button">Prev</button>
      <% end %>
      Page: <%= @page %>
      <%= if @page * @page_size < @total do %>
        <button phx-click="next_page" class="button">Next</button>
      <% else %>
        <button class="button">Next</button>
      <% end %>
      Total: <%= @total %>

      <%= render_users(@page, @page_size) %>
    """
  end

  defp render_users(page, page_size) do
    offset = (page - 1) * page_size

    users =
      @pre_query
      |> limit([u], ^page_size)
      |> offset([u], ^offset)
      |> Repo.all()

    ~E"""
    <table class="table">
      <%= for user <- users do %>
        <tr>
          <td><%= UserView.render("user.html", %{user: user}) %></td>
        </tr>
      <% end %>
    </table>
    """
  end

  def handle_event("prev_page", _, socket) do
    new_total = maybe_update_total(socket.assigns.update?, socket.assigns.total)
    {:noreply, socket |> update(:page, &(&1 - 1)) |> assign(total: new_total)}
  end

  def handle_event("next_page", _, socket) do
    new_total = maybe_update_total(socket.assigns.update?, socket.assigns.total)
    {:noreply, socket |> update(:page, &(&1 + 1)) |> assign(total: new_total)}
  end

  defp maybe_update_total(true, _total) do
    Repo.one(from(u in User, select: count(u)))
  end

  defp maybe_update_total(false, total), do: total
end
