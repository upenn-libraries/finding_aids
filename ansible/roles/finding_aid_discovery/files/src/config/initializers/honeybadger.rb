# frozen_string_literal: true

# Adding Honeybadger configuration.
if Rails.env.production? || Rails.env.staging?
  Rails.application.config.to_prepare do
    Honeybadger.configure do |config|
      config.api_key = SecretsService.lookup(key: 'honeybadger_api_key')
    end
  end
end
