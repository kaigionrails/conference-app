# https://docs.sentry.io/platforms/ruby/guides/rails/
Sentry.init do |config|
  config.dsn = Rails.configuration.x.sentry.dsn
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.environment = Rails.configuration.x.sentry.env

  # To activate performance monitoring, set one of these options.
  # We recommend adjusting the value in production:
  config.traces_sample_rate = 0.0
end
