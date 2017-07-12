ExUnit.start

Mix.Task.run "ecto.create", ~w(-r PhoenixSeaBattle.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r PhoenixSeaBattle.Repo --quiet)
Ecto.Adapters.SQL.Sandbox.mode(PhoenixSeaBattle.Repo, :manual)