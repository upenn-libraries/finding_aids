# frozen_string_literal: true

module Catalog
  # custom methods for our show page DocumentComponent
  # Copied from Blacklight 8.4.0
  class ShowDocumentComponent < Blacklight::DocumentComponent
    # Slot for the location details
    renders_one :repository_info, RepositoryInfoComponent
    # Slot for the collection inventory section
    renders_one :collection_inventory

    # Slots for collapsable metadata sections
    renders_many :collapsable_metadata_sections, 'CollapsableMetadataSection'

    # @return [ActiveSupport::SafeBuffer]
    def access_clarification_message
      content_tag :p, class: 'access-clarification' do
        content_tag :i do
          t('messages.access_clarification_html', repository: @document.repository)
        end
      end
    end

    # @return [ActiveSupport::SafeBuffer]
    def correction_email_link
      RepositoryContactLinks.correction(document: @document, request_url: request.original_url)
    end

    def before_render
      super
      with_repository_info(document: @document).with_address unless repository_info
    end

    # Component for a collapsable metadata section
    class CollapsableMetadataSection < ViewComponent::Base
      attr_reader :title, :open

      # @param title [String]
      # @param open [Boolean]
      def initialize(title:, open: false)
        @title = title
        @open = open
      end

      # @return [Boolean]
      def render?
        content.present?
      end

      def call
        render CollapsableSectionComponent.new(id: title.parameterize, open: open) do |section|
          section.with_title { title }
          section.with_body { content }
        end
      end
    end
  end
end
