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
      validate_encoding(DownloadService.fetch(url).body)
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

  # Extract all XML URLs present at the given URL.
  # If the URL is redirected, the redirected URL is used as the base for
  # constructing absolute URLs from relative links.
  #
  # @param [String] url The starting URL to fetch and scan for XML links.
  # @return [Array<XMLFile>] A list of XMLFile objects created from discovered XML URLs.
  def extract_xml_urls(url)
    # Use response object to access base_uri-like behavior (via response.env.url)
    response = DownloadService.fetch(url)
    doc      = Nokogiri::HTML.parse(response.body)
    base     = response.env.url.to_s

    hrefs(doc)
      .filter_map { |href| full_url href, base }
      .select { |uri| xml_path?(uri) }
      .map { |uri| XMLFile.new(url: uri.to_s) }
  end

  # Extract all href attribute values from <a> tags.
  #
  # @param [Nokogiri::HTML::Document] doc The parsed HTML document.
  # @return [Array<String>] An array of raw href values.
  def hrefs(doc)
    doc.xpath('//a/@href').map(&:value)
  end

  # Determines whether a URI's path ends with `.xml`.
  #
  # @param [URI, nil] uri The URI object to inspect.
  # @return [Boolean] True if the URI represents an XML file path.
  def xml_path?(uri)
    uri&.path&.end_with?('.xml')
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
