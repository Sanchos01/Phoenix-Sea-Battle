# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :phoenix_sea_battle,
  ecto_repos: [PhoenixSeaBattle.Repo],
  msg_count: 20

config :phoenix, :json_library, Jason
config :phoenix, template_engines: [leex: Phoenix.LiveView.Engine]

# Configures the endpoint
config :phoenix_sea_battle, PhoenixSeaBattleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GdMl3er/H5562PpEcWuZhDELgZhen1bufkuMrTMeVpBVM8GS4U3h5t93kq0gpEUj",
  render_errors: [view: PhoenixSeaBattleWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: PhoenixSeaBattle.PubSub,
  live_view: [signing_salt: "T7tp90J9XJ3qpScUicyq/af1qvT/I2Ca"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
