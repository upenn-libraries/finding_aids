# frozen_string_literal: true

module Ead
  module Parsing
    # Provide access to Ead XML nodes
    class ArchivalDescription
      ADMIN_INFO_SECTIONS = %w[publisher author date sponsor accessrestrict userestrict].freeze
      OTHER_SECTIONS = %w[bioghist scopecontent arrangement relatedmaterials bibliography odd accruals
                          custodhist altformavail originalsloc fileplan acqinfo otherfindaid phystech
                          processinfo relatedmaterial separatedmaterial appraisal].freeze

      # @param [String] xml
      def initialize(xml)
        @nodes = Nokogiri::XML.parse(xml)
        @nodes.remove_namespaces!
      end

      # @return [Nokogiri::XML::Element] required element in <archdesc> node
      def did
        @nodes.at_xpath('/ead/archdesc/did')
      end

      # @return [Nokogiri::XML::Element]
      def dsc
        @nodes.at_xpath('/ead/archdesc/dsc')
      end

      # @return [Nokogir::XML::Element]
      def langmaterial
        did.at_xpath('langmaterial')
      end

      # Dynamically define accessor methods for sections found in the archdesc node
      (ADMIN_INFO_SECTIONS + OTHER_SECTIONS).each do |section|
        define_method(section) do
          @nodes.xpath("/ead/archdesc/#{section}")
        end
      end
    end
  end
end
