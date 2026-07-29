# frozen_string_literal: true

module FeaturedCollections
  # Form for creating featured collections. Renders the repository and title
  # select dropdowns, wired to a Stimulus controller that filters titles
  # when the repository selection changes.
  #
  # @example
  #   <%= render FeaturedCollections::FormComponent.new(guide: @guide, titles_by_repository: @titles_by_repository) %>
  class FormComponent < ViewComponent::Base
    # @param guide [FeaturedCollection] new or persisted record
    # @param titles_by_repository [Hash{String => Array<String>}] repo → sorted title list
    def initialize(guide:, titles_by_repository:)
      @guide = guide
      @titles_by_repository = titles_by_repository
    end

    # @return [Array<String>] repository names sorted alphabetically
    def repositories
      @titles_by_repository.keys.sort
    end
  end
end
