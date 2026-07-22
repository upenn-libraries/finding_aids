# frozen_string_literal: true

# Blacklight class wrapping the retrieved Solr document
class SolrDocument
  XML_FIELD_NAME = :xml_ss

  include Blacklight::Solr::Document
  # self.unique_key = 'id'

  # Support EAD XML export format
  SolrDocument.use_extension(Support::EadXmlExport)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # @return [Ead::Parsing::ArchivalDescription]
  def parsed_ead
    @parsed_ead ||= Ead::Parsing::ArchivalDescription.new(fetch(XML_FIELD_NAME))
  end

  # @return [Ead::Extraction::ArchivalDescription]
  def ead_extraction
    @ead_extraction ||= Ead::Extraction::ArchivalDescription.new(parsed_ead)
  end

  # Main accessor method for configured fields. Forwards messages to the ead_extraction.
  # @param method [Symbol]
  def extract(method)
    ead_extraction.send method
  end

  # @return [Array<String> (frozen)]
  def display_dates
    fetch(:display_date_ssim, [])
  end

  # @return [String (frozen)]
  def title
    fetch(:title_tsi, '')
  end

  # @return [String (frozen)]
  def call_num
    fetch(:pretty_unit_id_ss, '')
  end

  # @return [String (frozen)]
  def repository
    fetch(:repository_ssi, '')
  end

  # @return [String]
  def repository_address
    fetch(:repository_address_ssi, nil)
  end

  # @return [String, nil]
  def contact_email
    fetch(:contact_emails_ssm).first
  end

  # @return [Hash{Symbol->Unknown}]
  def requesting_info
    { title: title, call_num: call_num, repository: repository }
  end
end
