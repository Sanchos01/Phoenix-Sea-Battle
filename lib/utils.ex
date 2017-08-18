defmodule PhoenixSeaBattle.Utils do
  def timestamp() do
    {a, b, c} = :os.timestamp
    a * 1000_000_000 + b * 1000 + div(c, 1000)
  end
end