# frozen_string_literal: true

# Helper methods for the homepage redesign.
# Owns URL/facet construction. Data loading is delegated to HomepageData.
module HomepageHelper
  # Randomly sample collection guides for the homepage card grid.
  #
  # @param count [Integer] number of guides to sample (default: 8)
  # @return [Array<OpenStruct>] sampled guide objects with +name+, +collection+, +identifier+
  def sample_collection_guides(count = 8)
    guides = homepage_data.collection_guides
    guides.sample([count, guides.length].min)
  end

  # Randomly sample repositories for the homepage card grid and map.
  #
  # @param count [Integer] number of repositories to sample (default: 6)
  # @return [Array<OpenStruct>] sampled repo objects with +name+, +slug+, +count+, +lat+, +lng+
  def sample_repositories(count = 6)
    repos = homepage_data.repositories
    repos.sample([count, repos.length].min)
  end

  # All repositories for map markers (not sampled).
  #
  # @return [Array<OpenStruct>] all repo objects
  def all_repositories
    homepage_data.repositories
  end

  # Build a facet-filtered search URL for a given repository name.
  #
  # @example
  #   repository_facet_path("Haverford College Quaker & Special Collections")
  #   # => "/records?f%5Brepository_ssi%5D%5B%5D=Haverford+College+Quaker+%26+Special+Collections"
  #
  # @param repo_name [String] the repository display name
  # @return [String] search URL with repository_ssi facet constraint
  def repository_facet_path(repo_name)
    search_action_path(f: { repository_ssi: [repo_name] })
  end

  private

  # @return [HomepageData] memoized data loader
  def homepage_data
    @homepage_data ||= HomepageData.new
  end
end
