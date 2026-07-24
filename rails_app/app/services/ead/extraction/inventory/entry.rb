# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Provides useful data about a single <c> or <c01> through <c12> component in the EAD used to describe
      # hierarchical groupings of collection materials.
      class Entry < Extraction::Base
        ID_PREFIX = 'series'
        # @param node [Nokogiri::XML::Node]
        # @return [Array<Ead::Extraction::Inventory::Entry>]
        def self.build_entries(node)
          Parsing::Inventory.nodes(node).map { |n| new(Parsing::Inventory.new(n)) }
        end

        attr_reader :parser

        def initialize(parser)
          @parser = parser
        end

        # @param index [Integer]
        # @param parent_id [String, nil]
        # @return [String]
        def id(index:, parent_id: nil)
          "#{parent_id || ID_PREFIX}-#{index}"
        end

        # @return [String, nil]
        def unitid
          text_only parser.unitid
        end

        # @return [String, nil]
        def origination
          text_only parser.origination
        end

        # @return [String, nil]
        def extent
          text_only parser.extent
        end

        # @return [String, nil]
        def bulk_date
          text_only parser.bulk_date
        end

        # @return [String, nil]
        def non_bulk_date
          text_only parser.non_bulk_date
        end

        # @return [ActiveSupport::SafeBuffer, nil]
        def title_html
          @title_html ||= translate node: parser.unittitle
        end

        # @return [String, nil]
        def title_text
          text_only parser.unittitle
        end

        # @return [Array<ActiveSupport::SafeBuffer>]
        def descriptions
          @descriptions ||= parser.descriptions.filter_map { |node| translate(node: node) }
        end

        # @return [Array<Hash>]
        def description_definitions
          @description_definitions ||= definitions(parser.descriptions, remove_head: true) do |node, translation|
            Definition.new(text_only(parser.head(node)) || I18n.t("sections.#{node.name}"), translation)
          end
        end

        # @return [Array<Hash>]
        def identification_definitions
          @identification_definitions ||= definitions(parser.identifications) do |node, translation|
            Definition.new(node.attr('label') || I18n.t("inventory.sections.#{node.name}"), translation)
          end
        end

        # @return [Array<Ead::Extraction::Inventory::Container>]
        def containers
          @containers ||= parser.container.map do |c|
            Container.new type: c.attr(:type), local_type: c.attr(:localtype), text: text_only(c), label: c.attr(:label)
          end
        end

        # @return [Array<Ead::Extraction::Inventory::DigitalObject>]
        def digital_objects
          @digital_objects ||= parser.digital_objects.filter_map do |dao|
            href = dao.attr('href').to_s
            next unless DigitalObject.web_url?(href)

            DigitalObject.new href: href, title: dao.attr('title'), role: dao.attr('role')
          end
        end

        # @return [Array<Ead::Extraction::Inventory::Entry>]
        def children
          @children ||= self.class.build_entries(parser.node)
        end

        # @return [Boolean]
        def children?
          return @children.any? if defined?(@children)

          first_child.present?
        end

        # @return [Boolean]
        def additional_contents?
          parser.additional_metadata?
        end

        def first_child
          return @first_child if defined?(@first_child)

          @first_child = parser.first_child
        end
      end
    end
  end
end
