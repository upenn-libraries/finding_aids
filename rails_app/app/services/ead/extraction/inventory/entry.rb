# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Provides useful data about a single <c> or <c01> through <c12> component in the EAD used to describe
      # hierarchical groupings of collection materials.
      class Entry
        include EadTranslating
        include EadTextExtracting

        NODES = %w[c c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12].freeze
        DESCRIPTIVE_METADATA_SECTIONS = %w[bioghist arrangement scopecontent odd relatedmaterial
                                           userestrict altformavail].freeze
        IDENTIFICATION_METADATA_SECTIONS = %w[physdesc materialspec physloc].freeze

        attr_reader :node

        # @param entry [Ead::Extraction::Inventory::Entry]
        # @return [Nokogiri::XML::NodeSet]
        def self.nodes(node)
          node.xpath(NODES.map { |name| "./#{name}" }.join(' | '))
        end

        # @param entry [Ead::Extraction::Inventory::Entry]
        # @return [Array<Ead::Extraction::Inventory::Entry>]
        def self.build_entries(node)
          nodes(node).map { |n| new(n) }
        end

        # @param node [Nokogir::XML::Node]
        def initialize(node)
          @node = node
        end

        # @return [String, nil]
        def unitid
          text_only node.at_xpath("did/unitid[not(@audience='internal' or @type='aspace_uri')]")
        end

        # @return [String, nil]
        def origination
          text_only node.at_xpath('did/origination')
        end

        # @return [String, nil]
        def extent
          text_only node.at_xpath('did/physdesc/extent')
        end

        # @return [String, nil]
        def bulk_date
          text_only node.at_xpath('did/unitdate[@type=\'bulk\']')
        end

        # @return [String, nil]
        def non_bulk_date
          text_only node.at_xpath('did/unitdate[not(@type=\'bulk\')]')
        end

        # @return [ActiveSupport::SafeBuffer, nil]
        def title_html
          @title_html ||= translate node: node.at_xpath('did/unittitle')
        end

        # @return [String, nil]
        def title_text
          text_only node.at_xpath('did/unittitle')
        end

        # @return [Array<ActiveSupport::SafeBuffer>]
        def descriptive_metadata
          @descriptive_metadata ||= descriptive_metadata_nodes.filter_map { |node| translate(node: node) }
        end

        # @return [Array<Hash>]
        def descriptive_metadata_definitions
          @descriptive_metadata_definitions ||= descriptive_metadata_nodes.filter_map do |section|
            term = text_only(section.at_xpath('head'))
            definition = translate(node: section, remove_head: true)
            next if definition.blank?

            { term: term, definition: definition }
          end
        end

        # @return [Array<Hash>]
        def identification_metadata_definitions
          @identification_metadata_definitions ||= IDENTIFICATION_METADATA_SECTIONS.filter_map do |section|
            identification_node = node.at_xpath("did/#{section}")
            next unless identification_node

            term = identification_node.attr('label') || I18n.t("inventory.sections.#{section}")

            { term: term, definition: translate(node: identification_node) }
          end
        end

        # @return [Array<Ead::Extraction::Inventory::Container>]
        def containers
          @containers ||= node.xpath('did/container').map do |c|
            Container.new type: c.attr(:type), local_type: c.attr(:localtype), text: text_only(c), label: c.attr(:label)
          end
        end

        # @return [Array<Ead::Extraction::Inventory::DigitalObject>]
        def digital_archival_objects
          @digital_archival_objects ||= node.xpath('./did/dao | ./dao').filter_map do |dao|
            href = dao.attr('href').to_s
            next unless DigitalObject.web_url?(href)

            DigitalObject.new href: href, title: dao.attr('title'), role: dao.attr('role')
          end
        end

        # @return [Array<Ead::Extraction::Inventory::Entry>]
        def children
          @children ||= self.class.build_entries(node)
        end

        # @return [Boolean]
        def children?
          return @children.any? if defined?(@children)

          first_child_node.present?
        end

        # @return [Boolean]
        def additional_contents?
          descriptive_metadata_nodes.any? || identification_metadata_definitions.any? || digital_archival_objects.any?
        end

        private

        def descriptive_metadata_nodes
          @descriptive_metadata_nodes ||= node.xpath(DESCRIPTIVE_METADATA_SECTIONS.join(' | '))
        end

        def first_child_node
          @first_child_node ||= node.at_xpath(NODES.map { |name| "./#{name}" }.join(' | '))
        end
      end
    end
  end
end
