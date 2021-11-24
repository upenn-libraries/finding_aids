# First, load Cuprite Capybara integration
require "capybara/cuprite"

# Parse URL
# NOTE: REMOTE_CHROME_HOST should be added to Webmock/VCR allowlist if you use any of those.
REMOTE_CHROME_URL = ENV['CHROME_URL']
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).yield_self do |uri|
      [uri.host, uri.port]
    end
  end

# Check whether the remote chrome is running.
remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    false
  end

remote_options = remote_chrome ? { url: REMOTE_CHROME_URL } : {}

# We need to register our driver to be able to use it later
# with #driven_by method.
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      # See additional options for Dockerized environment in the respective section of this article
      browser_options: remote_chrome ? { "no-sandbox" => nil } : {},
      # Increase Chrome startup wait time (required for stable CI builds)
      process_timeout: 10,
      # Enable debugging capabilities
      inspector: true,
    }.merge(remote_options)
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :cuprite
