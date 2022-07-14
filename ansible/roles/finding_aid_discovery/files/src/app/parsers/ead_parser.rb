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

  # Site-wide identifier for an EAD record
  #
  # Each EAD should have a unit id that is unique for that repository. If this is ever not true,
  # the repository needs to fix their data. We are uppercasing the identifiers so they aren't
  # case-sensitive going forward.
  #
  # Note: This is not the same identifier that was used in the previous site.
  #
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def id(doc)
    id = unit_id(doc)&.gsub(/[^A-Za-z0-9.-]/, '')&.upcase
    raise 'Missing unit id' if id.blank?

    "#{@endpoint.slug}_#{id}"
  end

  # Legacy ID that was used in the previous site.
  #
  # The previous application union'ed two fields and the order in which those two fields
  # were joined was not consistent. Therefore to cover all of our bases we are generating
  # two possible legacy ids. We are also uppercasing the entire ID so that we can do
  # case-insensitive matching.
  #
  # @param [Nokogiri::XML::Document] doc
  # @return [Array<String>]
  def legacy_ids(doc)
    raw_id = ead_id(doc)
    raw_id = unit_id(doc) if raw_id.blank?
    raw_id = raw_id.gsub(/[^A-Za-z0-9]/, '')

    agency_code = doc.at_xpath('/ead/eadheader/eadid/@mainagencycode').try(:text)&.gsub(/[^A-Za-z0-9]/, '')

    [
      "#{@endpoint.slug}_#{agency_code}#{raw_id}",
      "#{@endpoint.slug}_#{raw_id}#{agency_code}"
    ].map(&:upcase).uniq
  end

  # Not always present...
  # https://www.loc.gov/ead/tglib/elements/eadid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def ead_id(doc)
    doc.at_xpath('.//eadheader/eadid').try(:text).try(:strip)
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def unit_id(doc)
    doc.at_xpath("/ead/archdesc/did/unitid[not(@audience='internal')]").try(:text).try(:strip)
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
    years = doc.xpath('/ead/archdesc/did/unitdate')&.sum([]) do |node|
      val = node.attr('normal') || node.text
      to_years_array val&.strip
    end
    (years || []).uniq.sort
  end

  # extract years from val based on range and date finding regex YEARS_REGEX
  # @param [String] val
  # @return [Array]
  def to_years_array(val)
    matches = val.scan YEARS_REGEX
    return [] if matches.empty?

    matches.sum([]) do |years|
      if years.compact.length == 1
        [years[0].to_i]
      elsif years[1] == '9999'
        (years[0].to_i..Time.zone.now.year).to_a
      else
        (years[0]..years[1]).to_a.map(&:to_i)
      end
    end.uniq
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
  # @return [String]
  def repository(doc)
    if doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).present?
      doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).try(:strip)
    else
      doc.at_xpath('/ead/archdesc/did/repository').try(:text).try(:strip)
    end
  end

  # Returns repository address provided, which often times includes phone number, email addresses and urls. For now,
  # we are removing additional information, but in future we could include it.
  #
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def repository_address(doc)
    # Attempt to extract repository address, if not found, try to extract publisher address if
    # publisher and repository are the same.
    repository_addresslines = doc.xpath('/ead/archdesc/did/repository/address/addressline')
    publisher_name = doc.at_xpath('/ead/eadheader/filedesc/publicationstmt/publisher').try(:text).try(:strip)

    addresslines = if repository_addresslines.present?
                     repository_addresslines
                   elsif publisher_name.eql?(repository(doc))
                     doc.xpath('/ead/eadheader/filedesc/publicationstmt/address/addressline')
                   end

    return if addresslines.blank?

    # Remove emails, URLs and phone numbers from address.
    addresslines = addresslines.map { |a| a.try(:text).try(:strip) }
                               .delete_if { |a| a.match?(/\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}|@|URL|http/) }
    addresslines.blank? ? nil : addresslines.join(', ')
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
    end.uniq
  end

  # TODO: determine what distinguishes this from the people/corp_names fields, functionally
  #       and if this is still warranted
  def names(doc)
    doc.xpath(".//controlaccess/persname | .//controlaccess/famname |
               .//controlaccess/corpname | //origination[@label='creator']").map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def people(doc)
    doc.xpath('.//controlaccess/persname | .//controlaccess/famname').map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def corp_names(doc)
    doc.xpath('.//controlaccess/corpname').map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def subjects(doc)
    doc.xpath('.//controlaccess/subject').map do |node|
      node.text.strip.gsub(/\s*\.\s*$/, '')
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def places(doc)
    doc.xpath('.//controlaccess/geogname').map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # https://www.loc.gov/ead/tglib/elements/language.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def languages(doc)
    doc.xpath('/ead/archdesc/did/langmaterial/language/@langcode').map do |node|
      code = node.text.try(:strip).try(:downcase)
      iso_entry = ISO_639.find_by_code code
      iso_entry&.english_name || code
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def donor(doc)
    doc.xpath(".//controlaccess/persname[@role='Donor (dnr)']").map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # https://www.loc.gov/ead/tglib/elements/genreform.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def genre_form(doc)
    doc.xpath('.//controlaccess/genreform').map do |node|
      node.text.try(:strip)
    end.uniq
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def link_url(doc)
    doc.at_xpath('/ead/eadheader/eadid/@url').try(:text).try(:strip)
  end

  # Returns truthy solr boolean value if record is penn record, otherwise returns a solr falsey value.
  #
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def upenn_record(doc)
    split_repositories(doc)[0] == 'University of Pennsylvania' ? 'T' : 'F'
  end

  # usage: { solr_field_name: value, ... }
  # @param [String] xml contents of xml file
  # @return [Hash]
  def parse(xml)
    doc = Nokogiri::XML.parse xml
    doc.remove_namespaces!
    {
      id: id(doc),
      legacy_ids_ssim: legacy_ids(doc),
      endpoint_ssi: @endpoint.slug,
      xml_ss: xml,
      link_url_ss: link_url(doc),
      ead_id_ssi: ead_id(doc),
      unit_id_tsi: unit_id(doc),
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
      repository_address_ssi: repository_address(doc),
      creators_ssim: creators(doc),
      people_ssim: people(doc),
      places_ssim: places(doc),
      corpnames_ssim: corp_names(doc),
      subjects_ssim: subjects(doc),
      upenn_record_bsi: upenn_record(doc),
      repository_name_component_1_ssi: split_repositories(doc)[0],
      repository_name_component_2_ssi: split_repositories(doc)[1],
      repository_name_component_3_ssi: split_repositories(doc)[2],
      donors_ssim: donor(doc),
      genre_form_ssim: genre_form(doc),
      names_ssim: names(doc)
    }
  end
end
