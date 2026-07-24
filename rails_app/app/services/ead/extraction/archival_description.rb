# frozen_string_literal: true

module Ead
  module Extraction
    # Provides extracted Ead data
    class ArchivalDescription < Extraction::Base
      attr_reader :parser

      def initialize(parser)
        @parser = parser
      end

      # @return [Array<Hash>]
      def description_definitions
        definitions(parser.descriptions, remove_head: true) do |node, translation|
          Definition.new(node.name, translation)
        end
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def use_restrictions
        translate(node: parser.userestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def access_restrictions
        translate(node: parser.accessrestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def sponsor
        translate(node: parser.sponsor, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def date
        translate(node: parser.date, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def author
        translate(node: parser.author, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def publisher
        translate(node: parser.publisher, remove_head: true)
      end

      # @return [String, nil]
      def language_note
        text_only(parser.langmaterial)
      end
    end
  end
end
