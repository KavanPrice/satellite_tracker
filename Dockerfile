FROM elixir:1.17-otp-26 AS builder

ENV MIX_ENV=prod
WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib

RUN mix compile
RUN mix release

# Final stage
FROM debian:bookworm-slim

RUN apt-get update -y && \
    apt-get install -y openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

ENV LANG=C.UTF-8
ENV MIX_ENV=prod

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/satellite_tracker ./

CMD ["bin/satellite_tracker", "start"]
