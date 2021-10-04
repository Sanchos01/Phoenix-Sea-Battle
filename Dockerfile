FROM elixir:1.12-alpine as asset-builder

ENV HOME=/app

RUN apk add --no-cache git

RUN mix do local.hex --force, local.rebar --force
# Cache elixir deps
COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

WORKDIR $HOME
RUN mix do deps.get, deps.compile, deploy.assets, phx.digest

########################################################################
FROM elixir:1.12-alpine as releaser

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
COPY assets $HOME/assets

WORKDIR $HOME

# Digest precompiled assets
COPY --from=asset-builder $HOME/priv/static/ $HOME/priv/static/

# Release
RUN mix release

########################################################################
FROM alpine:3.14

ENV LANG=en_US.UTF-8 \
    HOME=/app/ \
    VERSION=0.3.0 \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/sh \
    APP=phoenix_sea_battle

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash ncurses-libs ca-certificates openssl

COPY --from=releaser $HOME/rel/$APP $HOME
WORKDIR $HOME

ENTRYPOINT ["bin/phoenix_sea_battle"]
CMD ["start"]