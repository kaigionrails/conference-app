FROM public.ecr.aws/docker/library/ruby:3.4.4-bookworm

ENV LANG=ja_JP.UTF-8
ENV TZ=Asia/Tokyo

WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libvips \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.js + pnpm (pnpm itself is fetched by corepack per package.json's
# packageManager field; the prompt suppression keeps the build non-interactive)
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    corepack enable

COPY Gemfile Gemfile.lock /app/
RUN bundle install -j2

COPY package.json pnpm-lock.yaml /app/
RUN pnpm install --frozen-lockfile

COPY . /app
RUN bundle exec i18n export
RUN GITHUB_PRIVATE_KEY=sample REDIS_URL=sample VAPID_PUBLIC_KEY=sample VAPID_PRIVATE_KEY=sample VAPID_SUBJECT_MAILTO=sample APPLICATION_URL=sample \
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=sample ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=sample ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=sample \
    SECRET_KEY_BASE=sample RAILS_ENV=production bundle exec rails assets:precompile
# kamal verifies this label on the host after pulling, and refuses to deploy
# without it. Both destinations share this image, so the value must match
# `service` in config/deploy.yml -- do not override `service` per destination.
LABEL service="conference-app"

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
