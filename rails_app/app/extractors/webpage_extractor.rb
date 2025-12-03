# frozen_string_literal: true

# Extracts XML files linked to on any HTML webpage
class WebpageExtractor < BaseExtractor
  # @return [Array<XMLFile>]
  def files
    @files ||= extract_xml_urls(endpoint.webpage_url)
  end

  class XMLFile < BaseEadSource
    attr_accessor :url

    def initialize(url:)
      @url = url
    end

    # @return [String]
    def xml
      validate_encoding(DownloadService.fetch(url))
    end

    # Returns filename as the source_id
    #
    # @return [String]
    def source_id
      url.split('/').last.gsub(/(\.xml).*$/, '\1')
    end

    private

    # Convert string encoding to UTF-8, if encoded differently.
    #
    # @param [String] text
    def validate_encoding(text)
      return text if text.encoding == Encoding::UTF_8

      # Try to convert to UTF-8 encoding, if that doesn't work its possible
      # that its because the string is already in UTF-8 and the encoding
      # was set incorrectly on the object therefore we force the encoding.
      begin
        text.encode(Encoding::UTF_8)
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        text.force_encoding(Encoding::UTF_8)
      end
    end
  end

  private

  # Extract all xml urls present at the URL given. If URL is redirected, uses new redirected URL when creating
  # absolute URLs from relative URLs.
  #
  # @param [String] url
  # @return [Array[<XMLFile>]]
  def extract_xml_urls(url)
    # Getting response and storing it in a variable in order to use additional methods provided by OpenURI::Meta.
    # Specifically we are using the #base_uri method in order to generate accurate full URI's in case of redirection.
    response = DownloadService.fetch(url)
    doc = Nokogiri::HTML.parse(response.body)

    # Extract list of XML URLs
    doc.xpath('//a/@href')
       .filter_map { |node| full_url node.value, response.env.url.to_s }
       .select { |uri| uri.path&.ends_with? '.xml' }
       .map { |uri| XMLFile.new(url: uri.to_s) }
  end

  # Converts link into full url. If link is a relative link, it prepends the base uri to create a full url. If the link
  # is already a full url, it isn't changed.
  #
  # @param [URI::HTTPS] base_uri used to create full urls for relative links
  # @param [String] link
  # @return [NilClass, URI::HTTP, URI::Generic]
  def full_url(link, base_uri)
    uri = URI.parse link
    uri.is_a?(URI::HTTP) ? uri : URI.join(endpoint_url_dir(base_uri), link)
  rescue URI::InvalidURIError => _e # if its a malformed URL, ignore
    nil
  end

  # Prepare an endpoint index URI for concatenation with xml file name
  # @param [URI] base_uri
  # @return [String]
  def endpoint_url_dir(base_uri)
    uri = base_uri.to_s
    if uri.ends_with?('/')
      uri.to_s
    elsif uri.ends_with?('.htm') || uri.ends_with?('.html')
      uri.gsub(/(\w)+.htm(l)?$/, '')
    else
      "#{uri}/"
    end
  end
end
