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

  # @return [Hash{Symbol->Array}]
  def topics_hash
    # %i[people_ssim corpnames_ssim subjects_ssim places_ssim].sum([]) { |k| fetch(k, []) }
    {
      people_ssim: fetch(:people_ssim, []),
      corpnames_ssim: fetch(:corpnames_ssim, []),
      subjects_ssim: fetch(:subjects_ssim, []),
      places_ssim: fetch(:places_ssim, [])
    }
  end

  # @return [SolrDocument::ParsedEad]
  def parsed_ead
    @parsed_ead ||= ParsedEad.new(fetch(XML_FIELD_NAME))
  end

  class ParsedEad
    ADMIN_INFO_SECTIONS = %w[publisher author sponsor accessrestrict userestrict].freeze
    OTHER_SECTIONS = %w[bioghist scopecontent arrangement relatedmaterials bibliography odd accruals
                        custodhist altformavail originalsloc fileplan acqinfo otherfindaid phystech
                        processinfo relatedmaterial separatedmaterial appraisal].freeze

    # @param [String] xml
    def initialize(xml)
      @nodes = Nokogiri::XML.parse(xml)
      @nodes.remove_namespaces!
    end

    # @return [Nokogiri::XML::Element]
    def dsc
      @nodes.at_xpath('/ead/archdesc/dsc')
    end

    # @return [Nokogiri::XML::Element]
    def sponsor
      @nodes.at_xpath('/ead/eadheader/filedesc/titlestmt/sponsor')
    end

    # @return [Nokogiri::XML::Element]
    def author
      @nodes.at_xpath('/ead/eadheader/filedesc/author')
    end

    # @return [Nokogiri::XML::Element]
    def publisher
      @nodes.at_xpath('/ead/eadheader/filedesc/publicationstmt/publisher')
    end

    # @param [String, Symbol] name
    def respond_to_missing?(name, _include_private = false)
      name.to_s.in? OTHER_SECTIONS
    end

    # @param [Symbol] symbol
    def method_missing(symbol, *_args)
      raise NoMethodError unless respond_to_missing? symbol

      @nodes.xpath("/ead/archdesc/#{symbol}")
    end
  end
end
