class HtmlReader # URL extractor?
  attr_reader :url

  # In Harvester call:
  #   HtmlReader.new(url: 'https:/').extract

  def initialize(url:)
    @url = url
  end

  # Extract all XML urls present in source.
  def extract
    doc = Nokogiri::HTML.parse(URI.parse(url).open)

    # extract list of xml urls
    doc.xpath('//a/@href')
       .map(&:value)
       .select { |val| val.ends_with? '.xml' }
       .map do |u|
      if url[0..3] == 'http'
        u
      else
        "#{url}#{u}"
      end
    end
  end
end
