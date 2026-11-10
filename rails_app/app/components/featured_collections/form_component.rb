# frozen_string_literal: true

module FeaturedCollections
  # Form for creating featured collections. Renders the repository and title
  # select dropdowns, wired to a Stimulus controller that filters titles
  # when the repository selection changes.
  class FormComponent < ViewComponent::Base
    # @param guide [FeaturedCollection] new or persisted record
    def initialize(guide:)
      @guide = guide
    end
  end
end
