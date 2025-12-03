# frozen_string_literal: true

require 'faraday'

# downloads files, setting appropriate headers and retrying as needed
class DownloadService
  HEADERS = { 'User-Agent' => 'PACSCL Discovery harvester' }.freeze
  class DownloadServiceError < StandardError; end

  # @param [String] url
  def self.fetch(url)
    connection = Faraday.new do |f|
      f.request :retry,
                max: 3,
                interval: 6,
                exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed]
    end
    response = connection.get(url, {}, HEADERS)
    return response.body if response.success?

    raise DownloadServiceError, "Download service failed: #{response.status} - #{response.body}"
  end
end
