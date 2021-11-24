class HtmlReader
  attr_accessor :files

  def initialize(html)
    # doc = Nokogiri::HTML.parse(
    #   open(url)
    # )
    # open url
    # get html
    doc = Nokogiri::HTML.parse(html)
    # extract list of xml files
    # @files = doc.xpath("//a[@href='ends-with(.xml)']/@href")
    @files = doc.xpath("//a/@href").map(&:value).select do |val|
      val.ends_with? '.xml'
    end
  end


end
