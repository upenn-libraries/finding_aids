# Parser for an Endpoint
# Takes a URL for an XML file and maps it to a Hash for indexing to Solr
# e.g., EadParser.new(endpoint_1).process(url_1)
class EadParser
  # @param [Endpoint] endpoint
  def initialize(endpoint)
    @endpoint = endpoint
  end

  # internal ID - used with delete logic at least
  # @return [String]
  # @param [String] url
  def id(url)
    "#{@endpoint.slug}_#{url.split('/').last.gsub('.xml', '')}"
  end

  # Not always present...
  # https://www.loc.gov/ead/tglib/elements/eadid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def ead_id(doc)
    doc.at_css('eadheader eadid').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def unit_id(doc)
    doc.at_css('archdesc did unitid').try :text
  end

  # @return [Array]
  def contact_emails
    @endpoint.public_contacts
  end

  # https://www.loc.gov/ead/tglib/elements/titleproper.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def title(doc)
    doc.at_css('eadheader titlestmt titleproper').try :text # this can/is/will be multivalued, sometimes with a 'filing' attr
    # if raw.index("\n")
    #   raw[..(raw.index("\n") - 2)] # strip at newline, often theres a <num /> element present...
    # else
    #   raw
    # end
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def extent(doc)
    doc.css('archdesc did physdesc extent').map { |t| t.try :text }
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def inclusive_date(doc)
    doc.at_css('archdesc did unitdate').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def abstract_scope_contents(doc)
    doc.at_css('archdesc did abstract').try :text
  end

  def date_added(doc)

  end

  def preferred_citation(doc)

  end

  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @return [Array]
  # @param [Nokogiri::XML::Document] doc
  def repositories(doc)
    doc.css('archdesc did repository').map do |node|
      node.text.try(:strip)
    end
  end

  # usage: { solr_field_name: value, ... }
  # @param [String] url url of xml file
  # @param [String] xml contents of xml file
  # @return [Hash]
  def parse(url, xml)
    doc = Nokogiri::XML.parse xml
    {
      id: id(url),
      endpoint_tsi: @endpoint.slug,
      xml_ts: xml,
      ead_id_tsi: ead_id(doc),
      unit_id_tsi: unit_id(doc),
      contact_emails_tsm: contact_emails,
      title_tsim: title(doc),
      extent_tsm: extent(doc),
      inclusive_date_ts: inclusive_date(doc),
      abstract_scope_contents_tsi: abstract_scope_contents(doc),
      repositories_tsim: repositories(doc)
    }
  end
end
