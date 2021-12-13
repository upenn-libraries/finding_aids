# Extracts URLs for XML files from an Endpoint's defined URL
# Usage: IndexExtractor.new(endpoint).files
class IndexExtractor
  attr_reader :endpoint

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
  end

  def files
    @files ||= extract_xml_urls(endpoint.url)
  end

  class XMLFile
    attr_reader :url

    # @param [String] url
    def initialize(url)
      @url = url
    end

    # @return [String]
    def read
      validate_encoding(fetch_xml)
    end

    private

    # Retrieve XML and retry if necessary.
    #
    # @return [String] xml string
    def fetch_xml
      Retryable.retryable(tries: 3, sleep: 6, on: OpenURI::HTTPError) do
        URI.parse(url).read
      end
    end

    # Convert string encoding to UTF-8 if encoded differently.
    #
    # @param [String] text
    def validate_encoding(text)
      return text if text.encoding == Encoding::UTF_8

      text.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
    end
  end

  private

  # Extract all xml urls present at the URL given.
  #
  # @param [String] url
  # @return [Array[<XMLFile>]]
  def extract_xml_urls(url)
    doc = Nokogiri::HTML.parse(URI.parse(url).open)

    # Extract list of XML URLs
    doc.xpath('//a/@href')
       .map(&:value)
       .select { |val| val.ends_with? '.xml' }
       .map { |u| u[0..3] == 'http' ? u : "#{url}#{u}" }
       .map { |xml_url| XMLFile.new xml_url }
  end
end
