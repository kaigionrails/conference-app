Sidekiq.configure_server do |config|
  config.redis = {url: Rails.configuration.redis_url}
  config.logger = Sidekiq::Logger.new($stdout)
  config.on(:startup) do
    schedule_path = Rails.root.join("config/job_schedule.yml")
    if File.exist?(schedule_path)
      Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_path) || {})
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: Rails.configuration.redis_url}
end
