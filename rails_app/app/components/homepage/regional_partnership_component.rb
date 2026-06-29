# frozen_string_literal: true

module Homepage
  # Regional-partnership band shown on the homepage and about page.
  # Contains a Leaflet map (driven by a Stimulus controller) and the
  # repository card grid (Homepage::RepositoryCardsComponent).
  #
  # @example
  #   render Homepage::RegionalPartnershipComponent.new(repos: @regional_repos)
  class RegionalPartnershipComponent < ViewComponent::Base
    # @param repos [Array<HomepageData::Repository>] repo objects with +name+, +count+, +lat+, +lng+
    def initialize(repos:)
      @repos = repos
    end

    def render?
      @repos.present?
    end
  end
end
