use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :phoenix_sea_battle, PhoenixSeaBattleWeb.Endpoint,
  http: [
    port: 4000,
    transport_options: [
      num_acceptors: 5
    ],
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      "--color",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :kernel,
  inet_dist_listen_min: 41014,
  inet_dist_listen_max: 41024

# Watch static and templates for browser reloading.
config :phoenix_sea_battle, PhoenixSeaBattleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/phoenix_sea_battle_web/views/.*(ex)$},
      ~r{lib/phoenix_sea_battle_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Switch off filtering passwords in logs
config :phoenix, :filter_parameters, []

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure your database
config :phoenix_sea_battle, PhoenixSeaBattle.Repo,
  username: "postgres",
  password: "postgres",
  database: "phoenix_sea_battle_dev",
  hostname: "localhost",
  pool_size: 10
