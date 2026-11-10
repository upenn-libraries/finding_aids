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

    # @return [ActiveSupport::SafeBuffer]
    def browse_all_link
      link_to(t('homepage.collection_guides.browse_all'),
              helpers.search_catalog_path(q: '', search_field: 'all_fields', sort: 'title-asc'))
    end

    # @param guide [FeaturedCollection]
    # @return [String]
    def guide_url(guide)
      helpers.solr_document_path(id: guide.record_id)
    end
  end
end
