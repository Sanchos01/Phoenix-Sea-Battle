defmodule PhoenixSeaBattle.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_sea_battle,
    adapter: Ecto.Adapters.Postgres
end
