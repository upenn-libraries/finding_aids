# frozen_string_literal: true

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
    doc.at_xpath('.//eadheader/eadid').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/unitid.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def unit_id(doc)
    doc.at_xpath("/ead/archdesc/did/unitid[not(@audience='internal')]").try :text
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
    raw_1 = doc.at_xpath('/ead/archdesc/did/physdesc[1]/extent[1]').try :text
    raw_2 = doc.at_xpath('/ead/archdesc/did/physdesc[1]/extent[2]').try :text
    raw_1.gsub!('.0', '')
    return raw_1 if raw_2.blank?

    "#{raw_1} (#{raw_2})"
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def inclusive_date(doc)
    raw = doc.at_xpath("/ead/archdesc/did/unitdate[@type='inclusive']").try :text
    return raw unless raw.blank?

    doc.at_xpath("/ead/archdesc/did/unitdate[not(@type='bulk')]").try :text
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def abstract_scope_contents(doc)
    raw = doc.at_xpath('.//archdesc/did/abstract').try :text
    raw || '' # TODO: confirm legacy indexing explicitly stored empty string here if text is not present
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def date_added(doc)
    doc.at_xpath('/ead/eadheader/profiledesc/creation/date')
       .try(:text)
      &.gsub(/T.*/, '')
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def preferred_citation(doc)
    doc.at_xpath('/ead/archdesc/prefercite/p').try :text
  end

  # Return an Array of the repository name split on any ':' present
  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def split_repositories(doc)
    @split_repositories ||= repository(doc).split(':').map(&:strip)
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def repository(doc)
    @repository ||= if doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text).present?
      doc.at_xpath('/ead/archdesc/did/repository/corpname').try(:text)
    else
      doc.at_xpath('/ead/archdesc/did/repository').try(:text)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def creators(doc)
    doc.xpath("/ead/archdesc/did/origination[@label='creator']/persname |
               /ead/archdesc/did/origination[@label='creator']/corpname |
               /ead/archdesc/did/origination[@label='creator']/famname").map do |node|
      node.text.try(:strip)
    end
  end

  # TODO: what distinguishes this from other fields, functionally?
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
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def places(doc)
    doc.xpath('.//controlaccess/geogname').map do |node|
      node.text.try(:strip)
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def languages(doc)
    doc.xpath('/ead/archdesc/did/langmaterial/language/@langcode').map do |node|
      code = node.text.try(:strip)
      iso_entry = ISO_639.find_by_code code
      iso_entry.english_name || code
    end
  end

  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def donor(doc)
    doc.xpath(".//controlaccess/persname[@role='Donor (dnr)']").map do |node|
      node.text.try(:strip)
    end
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
      ead_id_ssi: ead_id(doc),
      unit_id_ssi: unit_id(doc),
      contact_emails_ssm: contact_emails,
      title_tsim: title(doc),
      extent_ssi: extent(doc),
      inclusive_date_ss: inclusive_date(doc),
      # date_ss: TODO,
      date_added_ssi: date_added(doc),
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
      names_ssim: names(doc)
    }
  end
end
