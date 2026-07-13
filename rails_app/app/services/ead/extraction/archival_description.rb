# frozen_string_literal: true

module Ead
  module Extraction
    # Provides extracted Ead data
    class ArchivalDescription
      include EadTextExtracting
      include EadTranslating

      attr_reader :parsed_ead

      def initialize(parsed_ead)
        @parsed_ead = parsed_ead
      end

      # @return [Array<Symbol>]
      def description_sections
        parsed_ead.class::OTHER_SECTIONS
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def use_restrictions
        translate(node: parsed_ead.userestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def access_restrictions
        translate(node: parsed_ead.accessrestrict, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def sponsor
        translate(node: parsed_ead.sponsor, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def date
        translate(node: parsed_ead.date, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def author
        translate(node: parsed_ead.author, remove_head: true)
      end

      # @return [ActiveSupport::SafeBuffer, nil]
      def publisher
        translate(node: parsed_ead.publisher, remove_head: true)
      end

      # @return [String, nil]
      def language_note
        text_only(parsed_ead.langmaterial)
      end
    end
  end
end
