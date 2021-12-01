class HtmlReader # URL extractor?
  attr_reader :url

  # In Harvester call:
  #   HtmlReader.new(url: 'https:/').extract

  def initialize(url:)
    @url = url.ends_with?('/') ? url : url + '/' # Normalizing the link
  end

  # Extract all XML urls present in source.
  def extract
    doc = Nokogiri::HTML.parse(URI.open(url))

    # extract list of xml urls
    doc.xpath("//a/@href")
      .map(&:value)
      .select {  |val| val.ends_with? '.xml' }
      .map { |u| "#{url}#{u}" } # TODO: we don't always need to prefix like this...
  end
end
