class StandardEadIndexer
  def initialize(filename, endpoint)
    @filename = filename
    @endpoint = endpoint
    # TODO: consider
    # @document = Nokogiri::XML.parse URI.open filename
  end

  # internal ID - used with delete logic at least
  # @return [String]
  def id
    "#{@endpoint.slug}_#{@filename.gsub(@endpoint.slug, '')}"
  end

  # Not always present...
  # https://www.loc.gov/ead/tglib/elements/eadid.html
  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def ead_id(document)
    document.at_css('eadheader eadid').text
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def unit_id(document)
    document.at_css('archdesc did unitid').text
  end

  # @return [Array]
  def contact_emails
    @endpoint.public_contacts
  end

  # https://www.loc.gov/ead/tglib/elements/titleproper.html
  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def title(document)
    document.at_css('eadheader titlestmt titleproper').text # this can/is/will be multivalued, sometimes with a 'filing' attr
    # if raw.index("\n")
    #   raw[..(raw.index("\n") - 2)] # strip at newline, often theres a <num /> element present...
    # else
    #   raw
    # end
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @param [Nokogiri::XML::Document] document
  # @return [Array]
  def extent(document)
    document.css('archdesc did physdesc extent').map(&:text)
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def inclusive_date(document)
    document.at_css('archdesc did unitdate').text
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def abstract_scope_contents(document)
    document.at_css('archdesc did abstract').text
  end

  def date_added(document)

  end

  def preferred_citation(document)

  end

  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @param [Nokogiri::XML::Document] document
  # @return [Array]
  def repositories(document)
    document.css('archdesc did repository').map do |node|
      node.text.strip
    end
  end

  # @param [Nokogiri::XML::Document] document
  # @return [String]
  def xml(document)
    document.to_xml
  end

  # @return [Hash]
  # @param [Nokogiri::XML::Document] document?
  def process(document)
    # return JSON for Solr?
    # usage: { solr_field_name: value, ... }
    {
      id: id,
      endpoint_ts: @endpoint.slug,
      xml_ts: xml(document),
      ead_id_tsi: ead_id(document),
      unit_id_tsi: unit_id(document),
      contact_emails_tsm: contact_emails,
      title_tsim: title(document),
      extent_tsm: extent(document),
      inclusive_date_ts: inclusive_date(document),
      abstract_scope_contents_tsi: abstract_scope_contents(document),
      repositories_tsim: repositories(document)
    }
  end
end
