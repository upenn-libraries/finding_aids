# frozen_string_literal: true

module Homepage
  # Card grid displaying sampled collection guides on the homepage.
  # Data loading is handled by the controller; this component only renders
  # what it receives.
  #
  # @example
  #   render Homepage::CollectionGuideCardsComponent.new(guides: @homepage_guides)
  class CollectionGuideCardsComponent < ViewComponent::Base
    attr_reader :guides

    # @param guides [Array<OpenStruct>] guide objects with +name+, +collection+
    def initialize(guides:)
      @guides = guides
    end

    # Build a search URL for a given guide by name.
    # @param guide [OpenStruct] guide object responding to +name+
    # @return [String] search URL with name as query parameter
    def guide_search_url(guide)
      helpers.search_action_path(q: guide.name)
    end
  end
end
