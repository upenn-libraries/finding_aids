# frozen_string_literal: true

# Adapted from:
# https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# Usually, especially when using Selenium, developers tend to increase the max wait time.
# With Cuprite, there is no need for that.
# We use a Capybara default value here explicitly.
Capybara.default_max_wait_time = 2

# Normalize whitespaces when using `has_text?` and similar matchers,
# i.e., ignore newlines, trailing spaces, etc.
# That makes tests less dependent on slightly UI changes.
Capybara.default_normalize_ws = true

# Where to store system tests artifacts (e.g. screenshots, downloaded files, etc.).
# It could be useful to be able to configure this path from the outside (e.g., on CI).
Capybara.save_path = ENV.fetch('CAPYBARA_ARTIFACTS', './tmp/capybara')

# Make server accessible from the outside world
Capybara.server_host = '0.0.0.0'
# Use a hostname that could be resolved in the internal Docker network
# NOTE: Rails overrides Capybara.app_host in Rails <6.1, so we have
# to store it differently
# CAPYBARA_APP_HOST = "http://#{`hostname`.strip&.downcase || '0.0.0.0'}".freeze
# In Rails 6.1+ the following line should be enough
Capybara.app_host = "http://#{`hostname`.strip&.downcase || '0.0.0.0'}"

RSpec.configure do |config|
  # Make sure this hook runs before others
  config.prepend_before(:each, type: :system) do
    # Use JS driver always
    driven_by Capybara.javascript_driver
  end
end
