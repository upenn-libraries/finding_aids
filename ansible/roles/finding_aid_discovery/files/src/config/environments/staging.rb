# frozen_string_literal: true

require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Tell Action Mailer not to deliver emails to the real world.
  # The :file delivery method saves the emails in tmp/mails
  config.action_mailer.delivery_method = :file

  # Set hostname for urls generated within emails
  config.action_mailer.default_url_options = { host: 'pacscl-staging.library.upenn.edu' }

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :resque
  config.active_job.queue_name_prefix = 'finding_aid_discovery_staging'
end
