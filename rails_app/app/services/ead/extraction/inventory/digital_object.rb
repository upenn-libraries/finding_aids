# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Represents a single EAD <dao> component. Use it to build links to digital objects.
      class DigitalObject
        ONLINE_RESOURCE = 'Online Resource'

        attr_reader :href, :role, :title

        # @param href [String, nil]
        # @param role [String, nil]
        # @param title [String, nil]
        def initialize(href:, role:, title:)
          @href = href
          @role = role
          @title = title || ONLINE_RESOURCE
        end

        # Only display DAOs to web resources that are not IIIF URLS
        # @return [Boolean]
        def display?
          href.to_s.starts_with?('http') && !iiif_link?
        end

        private

        # @return [Boolean]
        def iiif_link?
          role.to_s.include?('https://iiif.io/api')
        end
      end
    end
  end
end
