FROM ruby:3.2.2
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev libvips
WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN bundle install
ENV LANG=ja_JP.UTF-8
ENV TZ=Asia/Tokyo
