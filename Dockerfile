# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.10
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails
ENV RAILS_ENV=staging \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

FROM base AS build
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential git libpq-dev pkg-config curl \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf ~/.bundle/ /usr/local/bundle/cache

COPY . .
RUN SECRET_KEY_BASE=dummy ./bin/rails assets:precompile
RUN bundle exec bootsnap precompile app/ lib/

FROM base
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq5 curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

RUN useradd rails --create-home --shell /bin/bash && chown -R rails:rails /rails
USER rails

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]