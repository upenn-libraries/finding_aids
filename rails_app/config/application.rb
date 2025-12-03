# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FindingAidDiscovery
  class Application < Rails::Application
    # Initialize configuration defaults for the new Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Eastern Time (US & Canada)'
    # config.eager_load_paths << Rails.root.join("extras")

    # Set hostname for urls generated within emails
    config.action_mailer.default_url_options = { host: ENV.fetch('FINDING_AID_DISCOVERY_URL') }

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Default hostname used for sitemap generation.
    config.default_host = URI::HTTPS.build host: ENV.fetch('FINDING_AID_DISCOVERY_URL').to_s

    # Read credentials key from Docker Secrets
    config.credentials.key_path = '/run/secrets/rails_master_key'
  end
end
