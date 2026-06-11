# frozen_string_literal: true

module Homepage
  # Repository card grid shown in the site-wide regional-partnership band
  # above the footer. The map div and its Stimulus controller live in the
  # parent partial (shared/_regional_partnership.html.erb); this component
  # owns the heading, intro copy, and card grid.
  #
  # @example
  #   render Homepage::RepositoryCardsComponent.new(repos: @regional_repos)
  class RepositoryCardsComponent < ViewComponent::Base
    attr_reader :repos

    # @param repos [Array<OpenStruct>] repo objects with +name+, +count+, +lat+, +lng+
    def initialize(repos:)
      @repos = repos
    end

    # Build a facet-filtered search URL for a given repository name.
    #
    # @param repo_name [String] the repository display name
    # @return [String] search URL with repository_ssi facet constraint
    def repository_facet_url(repo_name)
      helpers.search_action_path(f: { repository_ssi: [repo_name] })
    end

    # @return [String] the search-action URL for "browse all institutions"
    def browse_all_url
      helpers.search_action_path
    end

    # Serialize repository data as JSON for the Stimulus map controller.
    #
    # @return [String] JSON array of repo hashes
    def map_repos_json
      repos.map(&:to_h).to_json
    end
  end
end
