# frozen_string_literal: true

module Ead
  module Extraction
    # Extraction classes inherit shared behavior from this base class.
    # Collaborates with parsing and translation objects to provide data from an Ead.
    class Base
      Definition = Data.define(:term, :translation)

      private

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

      # @param nodeset [Nokogiri::XML::NodeSet, Array<Nokogiri::XML::Node>]
      # @param remove_head [Boolean]
      # @return [Array]
      def definitions(nodeset, remove_head: false)
        nodeset.filter_map do |node|
          translation = translate(node: node, remove_head: remove_head)
          next if translation.blank?

          yield node, translation
        end
      end
    end
  end
end
