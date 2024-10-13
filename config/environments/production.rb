require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {"cache-control" => "public, max-age=#{1.year.to_i}"}

  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :cloudflare
  config.active_storage.resolve_model_to_route = :rails_storage_proxy

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.logger = Logger.new($stdout)

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # config.active_job.queue_name_prefix = "conference_app_production"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  # config.action_mailer.default_url_options = { host: "example.com" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # https://logger.rocketjob.io/rails
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    $stdout.sync = true
    config.rails_semantic_logger.add_file_appender = false
    config.semantic_logger.add_appender(io: $stdout, formatter: config.rails_semantic_logger.format)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.session_store :redis_store,
    servers: [ENV.fetch("REDIS_URL")],
    key: "_conference_app_session",
    expire_after: 5.days

  config.x.webpush.vapid_public_key = ENV.fetch("VAPID_PUBLIC_KEY")
  config.x.webpush.vapid_private_key = ENV.fetch("VAPID_PRIVATE_KEY")
  config.x.webpush.vapid_subject_mailto = ENV.fetch("VAPID_SUBJECT_MAILTO")

  config.x.github.app_id = ENV["GITHUB_APP_ID"]
  config.x.github.private_key = ENV["GITHUB_PRIVATE_KEY"]
  config.x.github.client_id = ENV["GITHUB_KEY"]
  config.x.github.client_secret = ENV["GITHUB_SECRET"]
  config.x.github.oauth_redirect_url = ENV["GITHUB_OAUTH_REDIRECT_URI"]

  config.x.sentry.dsn = ENV["SENTRY_DSN"]
  config.x.sentry.env = ENV.fetch("SENTRY_ENV", "production")

  config.redis_url = ENV["REDIS_URL"]

  config.application_url = ENV.fetch("APPLICATION_URL")
  config.hosts << URI.parse(ENV.fetch("APPLICATION_URL")).host # e.g. "https://example.com" -> "example.com"

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
