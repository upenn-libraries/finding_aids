# frozen_string_literal: true

# Adding Honeybadger configuration.
if Rails.env.production? || Rails.env.staging?
  Honeybadger.configure do |config|
    config.api_key = SecretsService.lookup(key: 'honeybadger_api_key')
  end
end
