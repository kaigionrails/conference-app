Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') }
  config.logger = Sidekiq::Logger.new($stdout)
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL') }
end
