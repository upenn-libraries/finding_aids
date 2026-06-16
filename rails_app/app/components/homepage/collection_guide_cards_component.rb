# frozen_string_literal: true

module Homepage
  # Card grid displaying sampled collection guides on the homepage.
  # Data loading is handled by the controller; this component only renders
  # what it receives.
  #
  # @example
  #   render Homepage::CollectionGuideCardsComponent.new(guides: @homepage_guides)
  class CollectionGuideCardsComponent < ViewComponent::Base
    # @param guides [Array<HomepageData::CollectionGuide>] guide objects with +name+, +collection+
    def initialize(guides:)
      @guides = guides
    end

    # Build a record URL for a given guide by identifier.
    # @param guide [HomepageData::CollectionGuide] guide object responding to +identifier+
    # @return [String] URL to the catalog record
    def guide_record_url(guide)
      helpers.solr_document_path(guide.identifier)
    end
  end
end
