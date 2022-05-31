# frozen_string_literal: true

# First, load Cuprite Capybara integration
require 'capybara/cuprite'

# Ferrum logger class that allows Chrome container console messages to be shown in rspec output
class FerrumLogger
  def puts(log_str)
    _log_symbol, _log_time, log_body_str = log_str.strip.split(' ', 3)

    return if log_body_str.nil?

    log_body = JSON.parse(log_body_str)

    case log_body['method']
    when 'Runtime.consoleAPICalled'
      console_call log_body
    when 'Runtime.exceptionThrown'
      # noop, this is already logged because we have "js_errors: true" in cuprite.
    when 'Log.entryAdded'
      Kernel.puts "#{log_body['params']['entry']['url']} - #{log_body['params']['entry']['text']}"
    end
  end

  def console_call(log_body)
    log_body['params']['args'].each do |arg|
      case arg['type']
      when 'string'
        Kernel.puts arg['value']
      when 'object'
        Kernel.puts arg['preview']['properties'].to_h do |x|
          [x['name'], x['value']]
        end
      end
    end
  end
end

# Parse URL
# NOTE: REMOTE_CHROME_HOST should be added to Webmock/VCR allowlist if you use any of those.
REMOTE_CHROME_URL = ENV.fetch('CHROME_URL')
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).then do |uri|
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
      browser_options: remote_chrome ? { 'no-sandbox' => nil } : {},
      # Increase Chrome startup wait time (required for stable CI builds)
      process_timeout: 10,
      # Enable debugging capabilities
      inspector: true,
      js_errors: true,
      logger: FerrumLogger.new
    }.merge(remote_options)
  )
end

# Configure Capybara to use :cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :cuprite
