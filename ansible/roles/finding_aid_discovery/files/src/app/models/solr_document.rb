# frozen_string_literal: true

class SolrDocument
  XML_FIELD_NAME = :xml_ss

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

  # @return [SolrDocument::ParsedEad]
  def parsed_ead
    @parsed_ead ||= ParsedEad.new(fetch(XML_FIELD_NAME))
  end

  class ParsedEad
    # @param [String] xml
    def initialize(xml)
      @nodes = Nokogiri::XML.parse(xml)
      @nodes.remove_namespaces!
    end

    # @return [Nokogiri::XML::Element]
    def biog_hist
      @biog_hist ||= @nodes.at_xpath('/ead/archdesc/bioghist')
    end

    # @return [Nokogiri::XML::Element]
    def scope_content
      @scope_content ||= @nodes.at_xpath('/ead/archdesc/scopecontent')
    end

    # @return [Nokogiri::XML::Element]
    def dsc
      @dsc ||= @nodes.at_xpath('/ead/archdesc/dsc')
    end

    # @return [Nokogiri::XML::Element]
    def arrangement
      @dsc ||= @nodes.at_xpath('/ead/archdesc/arrangement')
    end
  end
end
