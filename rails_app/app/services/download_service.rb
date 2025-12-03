# frozen_string_literal: true

require 'faraday'
require 'faraday/follow_redirects'

# downloads files, setting appropriate headers and retrying as needed
class DownloadService
  HEADERS = { 'User-Agent' => 'PACSCL Discovery harvester' }.freeze
  class Error < StandardError; end

  class << self
    # @param [String] url
    # @return [Faraday::Response]
    def fetch(url)
      connection = Faraday.new do |f|
        f.response :follow_redirects
        f.request :retry,
          max: 3,
          interval: 6,
          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]
      end
      response = connection.get(url, {}, HEADERS)

      return response if response.success?

      error = format_webpage_error_response(response)

      raise Error, [response.status, error].join(' ')
    end

    private

    def format_webpage_error_response(response)
      if response.headers['Content-Type'] == 'application/json'
        JSON.parse(response.body)['errors'].join(' ')
      else
        response.body
      end
    end
  end
end
