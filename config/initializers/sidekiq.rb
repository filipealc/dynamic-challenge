require "sidekiq"
require "sidekiq-cron"

# Configure Sidekiq
Sidekiq.configure_server do |config|
  redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  redis_config = { url: redis_url }

  # Add SSL configuration for Heroku Redis
  if redis_url.start_with?("rediss://")
    redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  end

  config.redis = redis_config

  # Load cron jobs
  schedule_file = Rails.root.join("config", "sidekiq.yml")

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)[:cron]
  end
end

Sidekiq.configure_client do |config|
  redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  redis_config = { url: redis_url }

  # Add SSL configuration for Heroku Redis
  if redis_url.start_with?("rediss://")
    redis_config[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  end

  config.redis = redis_config
end
