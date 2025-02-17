source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "8.0.0.1"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.6"

gem "rack-contrib", "~> 2.5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.3"

gem "redis-actionpack"
gem "redis-store"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.14"

gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-github"

gem "faraday"
gem "faraday-retry"
gem "faraday-multipart"
gem "octokit"
gem "open-uri"

gem "amazing_print"
gem "rails_semantic_logger"
gem "woothee"

gem "sentry-rails"
gem "scout_apm"
gem "jwt"

gem "aws-sdk-s3", require: false

gem "kaminari"

gem "commonmarker", ">= 1.0.4"
gem "active_decorator"

gem "web-push"

gem "solid_queue"
gem "mission_control-jobs"

gem "alba"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]

  gem "factory_bot_rails", "~> 6.4.4"
  gem "rspec-rails", "~> 7.1"

  gem "standard"
  gem "standard-rails"

  gem "prosopite"
  gem "pg_query"
  gem "webmock"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
  gem "rbs", require: false
  gem "rbs-inline", require: false
  gem "rbs_rails", require: false
  gem "steep", require: false
end
