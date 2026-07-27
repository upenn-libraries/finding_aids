# frozen_string_literal: true

module Ead
  module Parsing
    # Provide access to Ead XML nodes
    class ArchivalDescription
      ACCESS_SECTIONS = %w[accessrestrict userestrict].freeze
      DESCRIPTION_SECTIONS = %w[bioghist scopecontent arrangement relatedmaterials bibliography odd accruals
                                custodhist altformavail originalsloc fileplan acqinfo otherfindaid phystech
                                processinfo relatedmaterial separatedmaterial appraisal].freeze

      # @param [String] xml
      def initialize(xml)
        @nodes = Nokogiri::XML.parse(xml)
        @nodes.remove_namespaces!
      end

      def descriptions
        DESCRIPTION_SECTIONS.flat_map { |section| send(section) }.compact_blank
      end

      # @return [Nokogiri::XML::Node, nil] required element in <archdesc> node
      def did
        @nodes.at_xpath('/ead/archdesc/did')
      end

      # @return [Nokogiri::XML::Node, nil]
      def dsc
        @nodes.at_xpath('/ead/archdesc/dsc')
      end

      # @return [Nokogiri::XML::Node, nil]
      def sponsor
        @nodes.at_xpath('/ead/eadheader/filedesc/titlestmt/sponsor')
      end

      # @return [Nokogiri::XML::Node, nil]
      def author
        @nodes.at_xpath('/ead/eadheader/filedesc/titlestmt/author')
      end

      # @return [Nokogiri::XML::Node, nil]
      def publisher
        @nodes.at_xpath('/ead/eadheader/filedesc/publicationstmt/publisher')
      end

      # @return [Nokogiri::XML::Node, nil]
      def date
        @nodes.at_xpath('/ead/eadheader/filedesc/publicationstmt//date')
      end

      # @return [Nokogir::XML::Node, nil]
      def langmaterial
        did.at_xpath('langmaterial')
      end

      # Dynamically define accessor methods for sections found in the archdesc node
      (ACCESS_SECTIONS + DESCRIPTION_SECTIONS).each do |section|
        # @return [Nokogiri::XML::NodeSet]
        define_method(section) do
          @nodes.xpath("/ead/archdesc/#{section}")
        end
      end
    end
  end
end
