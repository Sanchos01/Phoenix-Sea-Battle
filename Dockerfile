FROM elixir:1.8.1-alpine as asset-builder-mix-getter

ENV HOME=/app

RUN apk add --no-cache git

RUN mix do local.hex --force, local.rebar --force
# Cache elixir deps
COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

WORKDIR $HOME
RUN mix deps.get

########################################################################
FROM node:6 as asset-builder

ENV HOME=/app
WORKDIR $HOME

COPY --from=asset-builder-mix-getter $HOME/deps $HOME/deps
COPY assets/ $HOME/assets

RUN cd assets && \
    npm install && \
    npm run deploy

########################################################################
FROM elixir:1.8.1-alpine as releaser

ENV HOME=/app

# dependencies for comeonin
RUN apk add --no-cache build-base cmake git

# Install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

# Cache elixir deps
COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

WORKDIR $HOME
ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile

COPY lib $HOME/lib
COPY priv $HOME/priv
COPY rel $HOME/rel

# Digest precompiled assets
COPY --from=asset-builder $HOME/priv/static/ $HOME/priv/static/

WORKDIR $HOME
RUN mix phx.digest

# Release
RUN mix release --env=$MIX_ENV --verbose

########################################################################
FROM alpine:3.9

ENV LANG=en_US.UTF-8 \
    HOME=/app/ \
    TERM=xterm \
    VERSION=0.2.0 \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/sh \
    APP=phoenix_sea_battle

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash ncurses-libs ca-certificates openssl

COPY --from=releaser $HOME/rel/$APP/releases/$VERSION/$APP.tar.gz $HOME
WORKDIR $HOME
RUN tar -xzf $APP.tar.gz && rm $APP.tar.gz

ENTRYPOINT ["/app/bin/phoenix_sea_battle"]
CMD ["foreground"]