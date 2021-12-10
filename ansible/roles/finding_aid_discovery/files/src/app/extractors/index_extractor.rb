class IndexExtractor
  include Enumerable

  attr_accessor :files

  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @files = extract_xml_urls_from endpoint.url
  end

  def each(&block)
    @files.each(&block)
  end

  def size
    @files.length
  end

  class XMLFile
    attr_reader :url

    # @param [String] url
    def initialize(url)
      @url = url
    end

    # @return [String]
    def read
      URI.parse(@url).read
    end
  end

  private

  # @param [String] url
  # @return [Array[<EndpointXmlFile>]]
  def extract_xml_urls_from(url)
    doc = Nokogiri::HTML.parse(URI.parse(url).open)

    # extract list of xml urls
    urls = doc.xpath('//a/@href')
              .map(&:value)
              .select { |val| val.ends_with? '.xml' }
              .map do |u|
      if u[0..3] == 'http'
        u
      else
        "#{url}#{u}"
      end
    end
    urls.map do |xml_url|
      XMLFile.new xml_url
    end
  end
end
