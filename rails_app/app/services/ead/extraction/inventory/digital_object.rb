# frozen_string_literal: true

module Ead
  module Extraction
    module Inventory
      # Represents a single EAD <dao> component. Use it to build links to digital objects.
      class DigitalObject
        IIIF_MANIFEST_ROLE = 'https://iiif.io/api/presentation/2.1/'
        ONLINE_RESOURCE = 'Online Resource'

        attr_reader :href, :role, :title

        # @param href [String]
        # @return [Boolean]
        def self.web_url?(href)
          href.to_s.starts_with? 'http'
        end

        # @param href [String]
        # @param role [String]
        # @param title [String]
        def initialize(href:, role:, title:)
          @href = href
          @role = role
          @title = title || ONLINE_RESOURCE
        end

        # @return [Boolean]
        def iiif?
          role == IIIF_MANIFEST_ROLE
        end
      end
    end
  end
end
