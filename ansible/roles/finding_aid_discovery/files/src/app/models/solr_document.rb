# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # Collection Inventory
  #
  # @return [Array<Hash>] Returns an array of collection hashes, that could potentially have nested collection hashes
  def collection_inventory
    ead = Nokogiri::XML.parse(fetch(:xml_ss))
    ead.remove_namespaces!

    collections(ead.at_xpath('/ead/archdesc/dsc').xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12'))
  end

  def collections(nodes)
    nodes.map do |c|
      collection(c)
    end
  end

  def collection(node)
    title = node.at_xpath('did/unittitle').try(:text) || '(No Title)'

    if (origination = node.at_xpath('did/origination').try(:text))
      title = "#{origination}. #{title}"
    end

    if (unitid = node.at_xpath('did/unitid[not(@audience=\'internal\')]').try(:text))
      title = "#{unitid}. #{title}"
    end

    if node.xpath('did/unitdate').present?
      non_bulk_date = node.at_xpath('did/unitdate[not(@type=\'bulk\')]').try(:text)
      bulk_date = node.at_xpath('did/unitdate[@type=\'bulk\']').try(:text)

      title.concat ", #{non_bulk_date}" if non_bulk_date
      title.concat " (#{bulk_date})"    if bulk_date
    end

    title.concat '.' unless title.ends_with?('.') # always add a period

    if (extent = node.at_xpath('did/physdesc/extent').try(:text))
      title.concat " #{extent.gsub(/(\d+)\.0/, '\1')}."
    end

    containers = node.xpath('did/container').map { |container| { type: container.attr(:type).titlecase, text: container.try(:text) } }

    if (descriptive_nodes = node.xpath('arrangement | scopecontent | odd'))
      descriptive_data = descriptive_nodes.map do |d|
        {
          header: d.at_xpath('head').try(:text).try(:titlecase),
          text: d.xpath('p').map(&:text)
        }
      end
    end

    {
      title: title,
      containers: containers,
      descriptive_data: descriptive_data,
      subcollections: collections(node.xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12'))
    }
  end
end
