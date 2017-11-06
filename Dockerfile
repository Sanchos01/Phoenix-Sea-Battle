FROM elixir:1.5-alpine as asset-builder-mix-getter

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
COPY ./ ./

RUN npm install
RUN ./node_modules/.bin/webpack -p

########################################################################
FROM elixir:1.5-alpine as releaser

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

COPY . $HOME/

# Digest precompiled assets
COPY --from=asset-builder $HOME/priv/static/ $HOME/priv/static/

WORKDIR $HOME
RUN mix phoenix.digest

# Release
RUN mix release --env=$MIX_ENV --verbose

########################################################################
FROM alpine:3.6

ENV LANG=en_US.UTF-8 \
    HOME=/app/ \
    TERM=xterm

ENV VERSION=0.0.1

RUN apk add --no-cache bash ncurses-libs openssl

ENV MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/sh

COPY --from=releaser $HOME/rel/phoenix_sea_battle/releases/$VERSION/phoenix_sea_battle.tar.gz $HOME
WORKDIR $HOME
RUN tar -xzf phoenix_sea_battle.tar.gz

ENTRYPOINT ["/app/bin/phoenix_sea_battle"]
CMD ["foreground"]