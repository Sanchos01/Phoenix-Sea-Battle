defmodule PhoenixSeaBattleWeb.UserLive.New do
  use PhoenixSeaBattleWeb, :live_view

  alias PhoenixSeaBattle.{User, Repo}
  alias PhoenixSeaBattleWeb.Router.Helpers, as: Routes

  def mount(_params, _session, socket) do
    socket = assign(socket, changeset: User.changeset(%User{}), error: nil, timer: nil)
    {:ok, socket}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> User.changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    %User{}
    |> User.registration_changeset(user_params)
    |> Repo.insert()
    |> case do
      {:ok, %User{}} ->
        socket =
          socket
          |> put_flash(:info, "User created, login for access to service")
          |> redirect(to: Routes.session_path(socket, :new))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        error = "Oops, something going wrong! Please check the errors below."
        ref = make_ref()
        Process.send_after(self(), {:cancel_error, ref}, 5_000)
        {:noreply, assign(socket, changeset: changeset, error: error, timer: ref)}
    end
  end

  def handle_info({:cancel_error, ref}, socket = %{assigns: %{timer: ref}}) do
    {:noreply, assign(socket, error: nil, timer: nil)}
  end

  def handle_info({:cancel_error, _ref}, socket) do
    {:noreply, socket}
  end
end
