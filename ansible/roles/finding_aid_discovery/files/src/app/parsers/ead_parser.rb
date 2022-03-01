# frozen_string_literal: true

# Parser for an Endpoint
# Takes a URL for an XML file and maps it to a Hash for indexing to Solr
# e.g., EadParser.new(endpoint_1).process(url_1)
class EadParser
  YEARS_REGEX = %r{[a-zA-Z]*\s* # match any preceding text or whitespace
                  (?<begin>\d{4}) # capture 'begin' date if a range
                  \s* # any additional whitespace that may be present
                  (?: # optionally match range component
                    (?:-|to|/) # supported range separators
                    \s* # allow for more white space
                    [a-zA-Z]*\s* # # any more preceding text or whitespace
                    (?<end>\d{4}) # second capture group for 'end' date
                  )?}x

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
    doc.at_xpath('.//eadheader/eadid').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def unit_id(doc)
    doc.at_xpath("/ead/archdesc/did/unitid[not(@audience='internal')]").try :text
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def pretty_unit_id(doc)
    unit_id(doc).gsub(/^[^.]*\./, '').strip
  end

  # @return [Array]
  def contact_emails
    @endpoint.public_contacts
  end

  # https://www.loc.gov/ead/tglib/elements/unittitle.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def title(doc)
    doc.at_xpath('/ead/archdesc/did/unittitle').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def extent(doc)
    raw1 = doc.at_xpath('/ead/archdesc/did/physdesc[1]/extent[1]').try :text
    raw2 = doc.at_xpath('/ead/archdesc/did/physdesc[1]/extent[2]').try :text
    raw1.gsub!('.0', '')
    return raw1.downcase if raw2.blank?

    "#{raw1} (#{raw2})".downcase
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def display_date(doc)
    doc.xpath('/ead/archdesc/did/unitdate').map do |node|
      value = node.text.try(:strip)
      if node.attr(:type).present?
        value = value.downcase.gsub(/^bulk,?/, '').strip
        "#{value} (#{node.attr(:type)})"
      else
        value
      end
    end
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def years(doc)
    years = doc.xpath('/ead/archdesc/did/unitdate')&.map do |node|
      val = node.attr('normal') || node.text.strip
      to_years_array val
    end
    years || []
  end

  # extract years from val based on range and date finding regex YEARS_REGEX
  # @param [String] val
  # @return [Array]
  def to_years_array(val)
    matches = val.scan YEARS_REGEX
    return [] if matches.empty?

    matches.map do |years|
      if years.compact.length == 1
        years[0].to_i
      elsif years[1] == '9999'
        (years[0].to_i..Time.zone.now.year).to_a
      else
        (years[0]..years[1]).to_a.map(&:to_i)
      end
    end.flatten.uniq.sort
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def abstract_scope_contents(doc)
    raw = doc.at_xpath('/ead/archdesc/did/abstract').try(:text).try(:strip)
    raw || ''
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def date_added(doc)
    doc.at_xpath('/ead/eadheader/profiledesc/creation/date')
       .try(:text)
      &.gsub(/T.*/, '')
  end

  # https://www.loc.gov/ead/tglib/elements/prefercite.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def preferred_citation(doc)
    doc.at_xpath('/ead/archdesc/prefercite/p').try(:text).try(:strip)
  end

  # Return an Array of the repository name split on any ':' present
  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def split_repositories(doc)
    repository(doc).split(':').map(&:strip)
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def repository(doc)
    if doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).present?
      doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).try(:strip)
    else
      doc.at_xpath('/ead/archdesc/did/repository').try(:text).try(:strip)
    end
  end

  # https://www.loc.gov/ead/tglib/elements/origination.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  # @param [TrueClass, FalseClass] show_role
  def creators(doc, show_role: false)
    doc.xpath("/ead/archdesc/did/origination[@label='creator']/persname |
               /ead/archdesc/did/origination[@label='creator']/corpname |
               /ead/archdesc/did/origination[@label='creator']/famname").map do |node|
      raw_name = node.text.try(:strip)
      raw_role = node.at_xpath('./@role').try(:text).try(:strip)
      if raw_role && show_role
        role = raw_role.gsub(/\(.*$/, '').strip
        "#{raw_name} (#{role})"
      else
        raw_name
      end
    end
  end

  # TODO: determine what distinguishes this from the people/corp_names fields, functionally
  #       and if this is still warranted
  def names(doc)
    doc.xpath(".//controlaccess/persname | .//controlaccess/famname |
               .//controlaccess/corpname | //origination[@label='creator']").map do |node|
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def people(doc)
    doc.xpath('.//controlaccess/persname | .//controlaccess/famname').map do |node|
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def corp_names(doc)
    doc.xpath('.//controlaccess/corpname').map do |node|
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def subjects(doc)
    doc.xpath('.//controlaccess/subject').map do |node|
      node.text.strip.gsub(/\s*\.\s*$/, '')
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def places(doc)
    doc.xpath('.//controlaccess/geogname').map do |node|
      node.text.try(:strip)
    end
  end

  # https://www.loc.gov/ead/tglib/elements/language.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def languages(doc)
    doc.xpath('/ead/archdesc/did/langmaterial/language/@langcode').map do |node|
      code = node.text.try(:strip).try(:downcase)
      iso_entry = ISO_639.find_by_code code
      iso_entry&.english_name || code
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def donor(doc)
    doc.xpath(".//controlaccess/persname[@role='Donor (dnr)']").map do |node|
      node.text.try(:strip)
    end
  end

  # https://www.loc.gov/ead/tglib/elements/genreform.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def genre_form(doc)
    doc.xpath('.//controlaccess/genreform').map do |node|
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def link_url(doc)
    doc.at_xpath('/ead/eadheader/eadid/@url').try(:text).try(:strip)
  end

  # usage: { solr_field_name: value, ... }
  # @param [String] url url of xml file
  # @param [String] xml contents of xml file
  # @return [Hash]
  def parse(url, xml)
    doc = Nokogiri::XML.parse xml
    doc.remove_namespaces!
    {
      id: id(url),
      endpoint_ssi: @endpoint.slug,
      xml_ss: xml,
      link_url_ss: link_url(doc),
      url_ss: url, # For debugging purposes
      ead_id_ssi: ead_id(doc),
      unit_id_ssi: unit_id(doc),
      pretty_unit_id_ss: pretty_unit_id(doc),
      contact_emails_ssm: contact_emails,
      title_tsi: title(doc),
      extent_ssi: extent(doc),
      display_date_ssim: display_date(doc),
      years_iim: years(doc),
      date_added_ss: date_added(doc),
      languages_ssim: languages(doc),
      abstract_scope_contents_tsi: abstract_scope_contents(doc),
      preferred_citation_ss: preferred_citation(doc),
      repository_ssi: repository(doc),
      creators_ssim: creators(doc),
      people_ssim: people(doc),
      places_ssim: places(doc),
      corpnames_ssim: corp_names(doc),
      subjects_ssim: subjects(doc),
      repository_name_component_1_ssi: split_repositories(doc)[0],
      repository_name_component_2_ssi: split_repositories(doc)[1],
      repository_name_component_3_ssi: split_repositories(doc)[2],
      donors_ssim: donor(doc),
      genre_form_ssim: genre_form(doc),
      names_ssim: names(doc)
    }
  end
end
