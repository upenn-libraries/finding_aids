# frozen_string_literal: true

module Homepage
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
