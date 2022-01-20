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
    doc.at_xpath('.//archdesc/did/unitid').try :text
  end

  # @return [Array]
  def contact_emails
    @endpoint.public_contacts
  end

  # https://www.loc.gov/ead/tglib/elements/unittitle.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def title(doc)
    doc.at_xpath('.//archdesc/did/unittitle').try :text # this can/is/will be multivalued, sometimes with a 'filing' attr
  end

  # https://www.loc.gov/ead/tglib/elements/extent.html
  # @param [Nokogiri::XML::Document] doc
  # @return [Array]
  def extent(doc)
    doc.xpath('.//archdesc/did/physdesc/extent').map { |t| t.try :text }
  end

  # https://www.loc.gov/ead/tglib/elements/unitdate.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def inclusive_date(doc)
    doc.at_xpath('.//archdesc/did/unitdate').try :text
  end

  # https://www.loc.gov/ead/tglib/elements/abstract.html
  # @param [Nokogiri::XML::Document] doc
  # @return [String]
  def abstract_scope_contents(doc)
    doc.at_xpath('.//archdesc/did/abstract').try :text
  end

  def date_added(doc); end

  def preferred_citation(doc); end

  # https://www.loc.gov/ead/tglib/elements/repository.html
  # @return [Array]
  # @param [Nokogiri::XML::Document] doc
  def repositories(doc)
    doc.xpath('.//archdesc/did/repository').map do |node|
      node.text.try(:strip)
    end
  end

  def creator(doc)
    doc.xpath('.//archdesc/did/origination[@label="creator"]').map do |node|
      node.text.try(:strip)
    end
  end

  def people(doc)
    doc.xpath('.//controlaccess/persname').map do |node|
      node.text.try(:strip)
    end
  end

  def corp_names(doc)
    doc.xpath('.//controlaccess/corpname').map do |node|
      node.text.try(:strip)
    end
  end

  def subjects(doc)
    doc.xpath('.//controlaccess/subject').map do |node|
      node.text.try(:strip)
    end
  end

  def places(doc)
    doc.xpath('.//controlaccess/geogname').map do |node|
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
      extent_ssim: extent(doc),
      inclusive_date_ss: inclusive_date(doc),
      abstract_scope_contents_tsi: abstract_scope_contents(doc),
      repositories_ssim: repositories(doc),
      creator_ssim: creator(doc),
      people_ssim: people(doc),
      places_ssim: places(doc),
      corpnames_ssim: corp_names(doc),
      subjects_ssim: subjects(doc)
    }
  end
end
