FROM public.ecr.aws/docker/library/ruby:3.3.4-bookworm

ENV LANG=ja_JP.UTF-8
ENV TZ=Asia/Tokyo

WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    libvips \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock /app/
RUN bundle install -j2

COPY . /app
RUN GITHUB_PRIVATE_KEY=sample REDIS_URL=sample VAPID_PUBLIC_KEY=sample VAPID_PRIVATE_KEY=sample VAPID_SUBJECT_MAILTO=sample APPLICATION_URL=sample \
    SECRET_KEY_BASE=sample RAILS_ENV=production bundle exec rails assets:precompile
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
