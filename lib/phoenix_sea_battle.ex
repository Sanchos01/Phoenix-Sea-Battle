defmodule PhoenixSeaBattle do
  use Application
  alias PhoenixSeaBattleWeb.Endpoint

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PhoenixSeaBattleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PhoenixSeaBattle.PubSub},
      # Start the Ecto repository
      PhoenixSeaBattle.Repo,
      # Start the endpoint when the application starts
      PhoenixSeaBattleWeb.Endpoint,
      # Start your own worker by calling: PhoenixSeaBattle.Worker.start_link(arg1, arg2, arg3)
      # {PhoenixSeaBattle.Worker, [arg1, arg2, arg3]},
      PhoenixSeaBattleWeb.Presence,
      PhoenixSeaBattle.Saver,
      PhoenixSeaBattle.LobbyArchiver,
      {Registry, [keys: :unique, name: PhoenixSeaBattle.Game.Registry]},
      PhoenixSeaBattle.Game.Supervisor
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixSeaBattle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
