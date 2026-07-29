# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Represents a single EAD <container> component. Ask it about the container used to hold material.
      class Container
        attr_reader :type, :text, :label

        # @param type [String]
        # @param local_type [String]
        # @param text [String, nil]
        # @param label [Strin, nil]
        def initialize(type:, local_type:, text:, label:)
          @type = (type || local_type).try(:titlecase)
          @text = text
          @label = label
        end

        # @return [String, nil]
        def barcode
          return if label.blank?

          label.match(/\[(.*?)\]/).try(:[], 1)
        end

        # @return [String]
        def to_s
          [type, text].compact_blank.join(' ')
        end
      end
    end
  end
end
