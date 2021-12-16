require 'open-uri'

class DownloadAgent
  HEADERS = { 'User-Agent' => 'PACSCL Discovery harvester' }

  # @param [String] url
  # @return [String]
  def self.read(url)
    URI.parse(url).read(HEADERS)
  end
end
