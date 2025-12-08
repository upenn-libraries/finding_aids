# frozen_string_literal: true

require 'faraday'
require 'faraday/follow_redirects'

# downloads files, setting appropriate headers and retrying as needed
class DownloadService
  HEADERS = { 'User-Agent' => 'PACSCL Discovery harvester' }.freeze

  # @param [String] url
  # @return [Faraday::Response]
  def self.fetch(url)
    connection = Faraday.new do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.request :retry,
                max: 3,
                interval: 6,
                exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]
    end

    connection.get(url, {}, HEADERS)
  end
end
