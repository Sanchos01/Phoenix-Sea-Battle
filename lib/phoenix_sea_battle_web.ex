defmodule PhoenixSeaBattleWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PhoenixSeaBattleWeb, :controller
      use PhoenixSeaBattleWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: PhoenixSeaBattleWeb

      alias PhoenixSeaBattle.Repo
      import Ecto
      import Ecto.Query

      import Plug.Conn
      import PhoenixSeaBattleWeb.Router.Helpers
      import PhoenixSeaBattleWeb.Gettext
      import PhoenixSeaBattleWeb.Auth, only: [authenticate_user: 2]
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/phoenix_sea_battle_web/templates",
                        namespace: PhoenixSeaBattleWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PhoenixSeaBattleWeb.Router.Helpers
      import PhoenixSeaBattleWeb.ErrorHelpers
      import PhoenixSeaBattleWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import PhoenixSeaBattleWeb.Auth, only: [authenticate_user: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      
      alias PhoenixSeaBattle.Repo
      import Ecto
      import Ecto.Query
      import PhoenixSeaBattleWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
