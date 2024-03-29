defmodule PhoenixSeaBattleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_sea_battle

  socket("/live", Phoenix.LiveView.Socket, websocket: [timeout: 45_000])

  # socket("/socket", PhoenixSeaBattleWeb.UserSocket,
  #   # or list of options
  #   websocket: true
  # )

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :phoenix_sea_battle,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_phoenix_sea_battle_key",
    signing_salt: "qke9F44U"
  )

  plug(PhoenixSeaBattleWeb.Router)
end
