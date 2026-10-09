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
    # @param repos [Array<HomepageData::Repository>] repo objects with +name+, +count+, +lat+, +lng+
    def initialize(repos:)
      @repos = repos
    end

    def browse_all_link
      link_to(t('homepage.regional_partnership.browse_all'),
              helpers.facet_catalog_path('repository_ssi', 'facet.sort': 'index'),
              data: { blacklight_modal: 'trigger', turbo: false })
    end

    # Build a facet-filtered search URL for a given repository name.
    #
    # @param repo_name [String] the repository display name
    # @return [String] search URL with repository_ssi facet constraint
    def repository_facet_url(repo_name)
      byebug
      helpers.search_action_path(f: { repository_ssi: [repo_name] }, sort: 'title-asc')
    end
  end
end
