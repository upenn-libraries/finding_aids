class StandardEadIndexer

  def initialize(filename, endpoint)
    @filename = filename
    @endpoint = endpoint
    @document = Nokogiri::XML.parse URI.parse(filename).open
  end

  # internal ID - used with delete logic at least
  # @return [String]
  def id
    "#{@endpoint.slug}_#{@filename.gsub(@endpoint.url, '')}"
  end

  # Not always present...
  # https://www.loc.gov/ead/tglib/elements/eadid.html
  # @return [String]
  def ead_id
    @document.at_css('eadheader eadid').text
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @return [String]
  def unit_id
    @document.at_css('archdesc did unitid').text
  end

  # @return [Array]
  def contact_emails
    @endpoint.public_contacts
  end

  # https://www.loc.gov/ead/tglib/elements/titleproper.html
  # @return [String]
  def title
    @document.at_css('eadheader titlestmt titleproper').text # this can/is/will be multivalued, sometimes with a 'filing' attr
    # if raw.index("\n")
    #   raw[..(raw.index("\n") - 2)] # strip at newline, often theres a <num /> element present...
    # else
    #   raw
    # end
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @return [Array]
  def extent
    @document.css('archdesc did physdesc extent').map(&:text)
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @return [String]
  def inclusive_date
    @document.at_css('archdesc did unitdate').text
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @return [String]
  def abstract_scope_contents
    @document.at_css('archdesc did abstract').text
  end

  def date_added

  end

  def preferred_citation

  end

  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @return [Array]
  def repositories
    @document.css('archdesc did repository').map do |node|
      node.text.strip
    end
  end

  # @return [String]
  def xml
    @document.to_xml
  end

  # usage: { solr_field_name: value, ... }
  # @return [Hash]
  def process
    {
      id: id,
      endpoint_ts: @endpoint.slug,
      xml_ts: xml,
      ead_id_tsi: ead_id,
      unit_id_tsi: unit_id,
      contact_emails_tsm: contact_emails,
      title_tsim: title,
      extent_tsm: extent,
      inclusive_date_ts: inclusive_date,
      abstract_scope_contents_tsi: abstract_scope_contents,
      repositories_tsim: repositories
    }
  end
end
