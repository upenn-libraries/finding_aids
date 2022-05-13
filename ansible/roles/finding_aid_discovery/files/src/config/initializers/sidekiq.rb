# frozen_string_literal: true

redis_connection = {
  url: ENV.fetch('REDIS_URL', 'localhost:6379'),
  username: ENV.fetch('REDIS_SIDEKIQ_USER', 'sidekiq'),
  password: SecretsService.lookup(key: 'redis_sidekiq_password')
}

# limit retries to 3
Sidekiq.default_job_options = { retry: 3 }

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
    name: 'Run harvesting jobs for all Endpoints',
    description: 'Enqueues PartnerHarvestJobs for Endpoints sorted by oldest updated_at value',
    cron: '0 5 * * 1,3,5', # 5AM MWF
    class: 'PartnerHarvestEnqueueJob',
    active_job: true
  )
end
