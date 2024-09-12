# frozen_string_literal: true

require Rails.root.join('config/environments/production')

Rails.application.configure do
  # Tell Action Mailer not to deliver emails to the real world.
  # The :file delivery method saves the emails in tmp/mails
  config.action_mailer.delivery_method = :file

  # Use sidekiq in staging
  config.active_job.queue_adapter = :sidekiq
end
