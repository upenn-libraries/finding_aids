# frozen_string_literal: true

# Homepage data from the database and Solr.
#
# Featured collections are curated via the FeaturedCollection admin.
# Repository coordinates are looked up from the Geocoding::Cache.
# Bulk geocoding (refresh!) lives in the service layer, not here.
module HomepageData
  MAX_GUIDES = 8

  Repository = Data.define(:name, :count, :lat, :lng, :records_url)

  class << self
    # @return [Config::Options] homepage data from config
    def hero_images
      Settings.homepage_images
    end

    # Random selection of selected guides to be shown on the homepage, up to MAX_GUIDES.
    # @return [Array<FeaturedCollection>]
    def collection_guides
      FeaturedCollection.order('RANDOM()').limit(MAX_GUIDES).to_a
    end

    # @param cache [Geocoding::Cache, nil] pass to bypass memoization
    # @return [Array<Repository>]
    def repositories(cache: nil)
      return build_repositories(cache) if cache

      @repositories ||= build_repositories(Geocoding::Cache.new)
    end

    # @param cache [Geocoding::Cache, nil] pass to bypass memoization
    # @return [Array<Hash>]
    def repositories_json(cache: nil)
      return repositories(cache: cache).map(&:to_h) if cache

      @repositories_json ||= repositories.map(&:to_h)
    end

    private

    # @param cache [Geocoding::Cache]
    # @return [Array<Repository>]
    def build_repositories(cache)
      counts = RepositoryQueries.facet_counts
      cache.entries.filter_map do |repo, entry|
        next if entry.key?(:_failed)

        count = counts.find { |e| e[:name] == repo }
        next unless count

        Repository.new(
          name: repo,
          count: count[:count],
          records_url: records_url_for(repo),
          lat: entry[:lat], lng: entry[:lng]
        )
      end
    end

    # @param name [String] repository name
    # @return [String] URL to filtered records page
    def records_url_for(name)
      Rails.application.routes.url_helpers.search_catalog_path(
        f: { repository_ssi: [name] }
      )
    end
  end
end
