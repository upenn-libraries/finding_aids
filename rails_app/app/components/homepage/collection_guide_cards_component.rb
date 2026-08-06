# frozen_string_literal: true

module Homepage
  # Card grid displaying curated collection guides on the homepage.
  #
  # @example
  #   render Homepage::CollectionGuideCardsComponent.new(guides: @homepage_guides)
  class CollectionGuideCardsComponent < ViewComponent::Base
    # @param guides [Array<FeaturedCollection>]
    def initialize(guides:)
      @guides = guides
    end

    # @param guide [FeaturedCollection]
    # @return [String]
    def guide_url(guide)
      solr_document_path(q: guide.id)
    end
  end
end
