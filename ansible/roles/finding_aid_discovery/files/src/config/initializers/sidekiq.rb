# frozen_string_literal: true

# Sidekiq/Redis configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'localhost:6379') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'localhost:6379') }
end

# Job schedule
if Sidekiq.server?
  Sidekiq::Cron::Job.create(
    name: 'Run harvesting jobs for the most out-of-date Endpoints',
    description: 'Will enqueue PartnerHarvestJobs for 10 (or a integer specified in HARVESTS_TO_ENQUEUE env var) ' /
                 'Endpoints sorted by oldest updated_at value',
    cron: '0 6 * * *', # 6AM everyday
    class: 'PartnerHarvestEnqueueJob',
    active_job: true
  )
end
