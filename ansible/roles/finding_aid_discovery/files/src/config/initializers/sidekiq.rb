# frozen_string_literal: true

redis_connection = {
  url: ENV.fetch('REDIS_URL', 'localhost:6379'),
  username: ENV.fetch('REDIS_SIDEKIQ_USER', 'sidekiq'),
  password: SecretsService.lookup(key: 'redis_sidekiq_password')
}

# Sidekiq/Redis configuration
Sidekiq.configure_server do |config|
  config.redis = redis_connection
end

Sidekiq.configure_client do |config|
  config.redis = redis_connection
end

# Job schedule
if Sidekiq.server?
  Sidekiq::Cron::Job.create(
    name: 'Run harvesting jobs for the most out-of-date Endpoints',
    description: 'Enqueues PartnerHarvestJobs for Endpoints sorted by oldest updated_at value',
    cron: '0 6 * * *', # 6AM everyday
    class: 'PartnerHarvestEnqueueJob',
    active_job: true
  )
end
