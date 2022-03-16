# frozen_string_literal: true

# Extracts XML files linked to on any HTML page
class IndexExtractor < BaseExtractor
  # @return [Array<XMLFile>]
  def files
    @files ||= extract_xml_urls(endpoint.url)
  end

  class XMLFile < BaseEadSource
    attr_accessor :url

    def initialize(url:)
      super id: id_from(url: url)
      @url = url
    end

    # @return [String]
    def xml
      validate_encoding(DownloadService.fetch(url))
    end

    private

    # ID is just the final component without any query params
    # @return [String]
    def id_from(url:)
      url.split('/').last.gsub(/\.xml.*$/, '')
    end

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

  # Extract all xml urls present at the URL given.
  #
  # @param [String] url
  # @return [Array[<XMLFile>]]
  def extract_xml_urls(url)
    # what if this redirects? we should log a message or raise an alert if this redirs and we join with the
    # original URL in #note_to_url the new derived URLs might not redirect to the XML files as expected
    # TODO: raise HB notice on redirect? auto-update Endpoint.url? save redirected URL for use in #node_to_uri?
    doc = Nokogiri::HTML.parse(DownloadService.fetch(url))

    # Extract list of XML URLs
    doc.xpath('//a/@href')
       .filter_map { |node| node_to_uri node }
       .select { |uri| uri.path&.ends_with? '.xml' }
       .map { |uri| XMLFile.new(url: uri.to_s) }
  end

  # @param [Nokogiri::XML::Attr] href_link
  # @return [NilClass, URI::HTTP, URI::Generic]
  def node_to_uri(href_link)
    val = href_link.value
    uri = URI.parse val
    if uri.is_a? URI::HTTP
      uri
    else
      normalized_endpoint_url = @endpoint.url.ends_with?('/') ? @endpoint.url : "#{@endpoint.url}/"
      URI.join(normalized_endpoint_url, val)
    end
  rescue URI::InvalidURIError => _e # if its a malformed URL, ignore
    nil
  end
end
