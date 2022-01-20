# frozen_string_literal: true

require 'open-uri'

# downloads files, setting appropriate headers and retrying as needed
class DownloadService
  HEADERS = { 'User-Agent' => 'PACSCL Discovery harvester' }.freeze

  # @param [String] url
  def self.fetch(url)
    Retryable.retryable(tries: 3, sleep: 6, on: OpenURI::HTTPError) do
      URI.parse(url).read(HEADERS)
    end
  end
end
