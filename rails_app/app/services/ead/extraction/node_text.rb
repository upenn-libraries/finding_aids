# frozen_string_literal: true

module Ead
  module Extraction
    # Utility class to extract text from XML node
    class NodeText
      class << self
        # @param node [Nokogori::XML::Node]
        # @return [String, nil]
        def text_only(node)
          node.try(:text).try(:strip)
        end

        # @param node [Nokogiri::XML::Node]
        # @param remove_head [Boolean]
        # @return [ActiveSupport::SafeBuffer, nil]
        def translate(node:, remove_head: false)
          Ead::Translation::Service.call(node: node, remove_head: remove_head)
        end

        # @param nodes [Nokogiri::XML::NodeSet]
        # @param remove_head [Boolean]
        # @return [ActiveSupport::SafeBuffer, nil]
        def translate_many(nodes, remove_head: false)
          translations = nodes.filter_map { |node| translate(node: node, remove_head: remove_head) }
          return if translations.blank?

          ActiveSupport::SafeBuffer.new(translations.join)
        end

        # @param nodeset [Nokogiri::XML::NodeSet, Array<Nokogiri::XML::Node>]
        # @param remove_head [Boolean]
        # @return [Array]
        def map_translations(nodeset, remove_head: false)
          nodeset.filter_map do |node|
            translation = translate(node: node, remove_head: remove_head)
            next if translation.blank?

            yield node, translation
          end
        end
      end
    end
  end
end
