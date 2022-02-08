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
    SECTIONS = %w[bioghist scopecontent arrangement relatedmaterials bibliography odd accruals accessrestrict
                  userestrict custodhist altformavail originalsloc fileplan acqinfo otherfindaid phystech
                  processinfo relatedmaterial separatedmaterial appraisal].freeze

    # @param [String] xml
    def initialize(xml)
      @nodes = Nokogiri::XML.parse(xml)
      @nodes.remove_namespaces!
    end

    # @return [Nokogiri::XML::Element]
    def dsc
      @dsc ||= @nodes.at_xpath('/ead/archdesc/dsc')
    end

    # @param [String, Symbol] name
    def respond_to_missing?(name, _)
      name.to_s.in? SECTIONS
    end

    # @param [Symbol] symbol
    def method_missing(symbol, *_args)
      memoize_section_text "@#{symbol}" do
        @nodes.at_xpath("/ead/archdesc/#{symbol}")
      end
    end

    # @param [String] name
    def memoize_section_text(name)
      return instance_variable_get(name) if instance_variable_defined?(name)

      instance_variable_set name, yield
    end
  end
end
