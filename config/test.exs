use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phoenix_sea_battle, PhoenixSeaBattleWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :phoenix_sea_battle, PhoenixSeaBattle.Repo,
  username: "postgres",
  password: "postgres",
  database: "phoenix_sea_battle_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :comeonin, :bcrypt_log_rounds, 4
config :comeonin, :pbkdf2_rounds, 1

config :phoenix_sea_battle, :game_live_timeout, 100
