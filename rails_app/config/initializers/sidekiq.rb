# frozen_string_literal: true

Rails.application.config.to_prepare do
  redis_connection = {
    url: ENV.fetch('REDIS_URL', 'localhost:6379'),
    username: ENV.fetch('REDIS_SIDEKIQ_USER', 'sidekiq'),
    password: DockerSecrets.lookup(:redis_sidekiq_password)
  }

  # limit retries to 3
  Sidekiq.default_job_options = { retry: 3 }

  # Sidekiq/Redis configuration
  Sidekiq.configure_server do |config|
    config.redis = redis_connection

    # TODO: Remove this configuration once a version of sidekiq-cron is released where jobs in config/schedule.yml
    #       are automatically loaded.
    config.on(:startup) do
      schedule_file = 'config/schedule.yml'
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_connection
  end
end
