# frozen_string_literal: true

module Ead
  module Extraction
    # Provides extracted Ead data
    class ArchivalDescription
      attr_reader :parser, :node_text

      def initialize(parser, node_text: NodeText)
        @parser = parser
        @node_text = node_text
      end

      # @return [Array]
      def description_definitions
        node_text.map_translations(parser.descriptions, remove_head: true) do |node, translation|
          node_text::Definition.new(node.name, translation)
        end
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def use_restrictions
        node_text.translate_many(parser.userestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def access_restrictions
        node_text.translate_many(parser.accessrestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def sponsor
        node_text.translate(node: parser.sponsor, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def date
        node_text.translate(node: parser.date, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def author
        node_text.translate(node: parser.author, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def publisher
        node_text.translate(node: parser.publisher, remove_head: true)
      end

      # @return [String, nil]
      def language_note
        node_text.text_only(parser.langmaterial)
      end
    end
  end
end
