# frozen_string_literal: true

module Ead
  module Parsing
    # Provide nodes from collection inventory
    class Inventory
      INVENTORY_NODES = %w[c c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12].freeze
      DESCRIPTIVE_NODES = %w[bioghist arrangement scopecontent odd relatedmaterial userestrict altformavail].freeze
      IDENTIFICATION_NODES = %w[physdesc materialspec physloc].freeze

      # @param entry [Ead::Extraction::Inventory::Entry]
      # @return [Nokogiri::XML::NodeSet]
      def self.nodes(node)
        node.xpath(INVENTORY_NODES.join(' | '))
      end

      attr_reader :node

      # @param node [Nokogiri::XML::Node]
      def initialize(node)
        @node = node
      end

      # @param node [Nokogiri::XML::Node]
      # @return [Nokogiri::XML::Node, nil]
      def head(node)
        node.at_xpath('head')
      end

      # @return [Nokogiri::XML::Node, nil]
      def unitid
        node.at_xpath("did/unitid[not(@audience='internal' or @type='aspace_uri')]")
      end

      # @return [Nokogiri::XML::Node, nil]
      def origination
        node.at_xpath('did/origination')
      end

      # @return [Nokogiri::XML::Node, nil]
      def extent
        node.at_xpath('did/physdesc/extent')
      end

      # @return [Nokogiri::XML::Node, nil]
      def bulk_date
        node.at_xpath('did/unitdate[@type=\'bulk\']')
      end

      # @return [Nokogiri::XML::Node, nil]
      def non_bulk_date
        node.at_xpath('did/unitdate[not(@type=\'bulk\')]')
      end

      # @return [Nokogiri::XML::Node, nil]
      def unittitle
        node.at_xpath('did/unittitle')
      end

      # @return [Nokogiri::XML::NodeSet]
      def container
        node.xpath('did/container')
      end

      # @return [Nokogiri::XML::NodeSet]
      def descriptions
        node.xpath(DESCRIPTIVE_NODES.join(' | ')).compact_blank
      end

      # @return [Nokogiri::XML::NodeSet]
      def identifications
        node.xpath(IDENTIFICATION_NODES.map { |name| "did/#{name}" }.join('|')).compact_blank
      end

      # @return [Nokogiri::XML::NodeSet]
      def digital_objects
        node.xpath('./did/dao | ./dao')
      end

      # @return [Nokogiri::XML::Node, nil]
      def first_child
        node.at_xpath(INVENTORY_NODES.join(' | '))
      end

      # @return [Boolean]
      def additional_metadata?
        descriptions.any? || identifications.any? || digital_objects.any?
      end
    end
  end
end
