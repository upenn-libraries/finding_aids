class StandardEadIndexer
  def initialize(filename, endpoint)
    @filename = filename
    @endpoint = endpoint
  end

  # internal ID - used with delete logic at least
  def id
    "#{@endpoint.slug}_#{@filename}"
  end

  # other classes could override these methods to changing how info is extracted from the EAD document
  # or override #process entirely
  def example(document); end

  # @return [Hash]
  # @param [Nokogiri::XML::Document] document?
  def process(document)
    # return JSON for Solr?
    # usage: { solr_field_name: value, ... }
    {
      id: id,
      # other: example(document)
    }
  end
end
