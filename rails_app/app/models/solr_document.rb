# frozen_string_literal: true

# Blacklight class wrapping the retrieved Solr document
class SolrDocument
  XML_FIELD_NAME = :xml_ss
  REQUESTABLE_REPOSITORIES = [
    AeonRequest::ARCHIVES_REPOSITORY_NAME,
    AeonRequest::KATZ_REPOSITORY_NAME,
    AeonRequest::KISLAK_REPOSITORY_NAME
  ].freeze

  include Blacklight::Solr::Document
  include EadTranslating
  include EadTextExtracting

  # self.unique_key = 'id'

  # Support EAD XML export format
  SolrDocument.use_extension(Support::EadXmlExport)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # @return [SolrDocument::ParsedEad]
  def parsed_ead
    @parsed_ead ||= SolrDocument::ParsedEad.new(fetch(XML_FIELD_NAME))
  end

  # @return [Array<Symbol>]
  def description_sections
    parsed_ead.class::OTHER_SECTIONS
  end

  # @return [String, nil]
  def use_restrictions
    translate(node: parsed_ead.userestrict, remove_head: true)
  end

  # @return [String, nil]
  def access_restrictions
    translate(node: parsed_ead.accessrestrict, remove_head: true)
  end

  # @return [String, nil]
  def sponsor
    translate(node: parsed_ead.sponsor, remove_head: true)
  end

  # @return [String, nil]
  def date
    translate(node: parsed_ead.date, remove_head: true)
  end

  # @return [String, nil]
  def author
    translate(node: parsed_ead.author, remove_head: true)
  end

  # @return [String, nil]
  def publisher
    translate(node: parsed_ead.publisher, remove_head: true)
  end

  # @return [String, nil]
  def language_note
    text_only(parsed_ead.langmaterial)
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

  # @return [Boolean]
  def requestable?
    fetch(:repository_ssi, nil).in? REQUESTABLE_REPOSITORIES
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
