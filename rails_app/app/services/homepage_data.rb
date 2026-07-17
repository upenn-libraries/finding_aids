# frozen_string_literal: true

# Homepage data from YAML and Solr.
#
# Repository coordinates are looked up from the Geocoding::Cache.
# Bulk geocoding (refresh!) lives in the service layer, not here.
# Collection guides are loaded from YAML.
module HomepageData
  COLLECTION_GUIDES_PATH = Rails.root.join('data/collection_guides.yml')

  CollectionGuide = Data.define(:identifier, :name, :collection)
  Repository = Data.define(:name, :slug, :count, :lat, :lng, :records_url)

  class << self
    # @return [Array<CollectionGuide>]
    def collection_guides
      @collection_guides ||= load_yaml(COLLECTION_GUIDES_PATH, CollectionGuide)
    end

    # @param cache [Geocoding::Cache, nil] explicit cache bypasses memoization;
    #   omit (or pass nil) for the default memoized path.
    # @return [Array<Repository>]
    def repositories(cache: nil)
      return build_repositories(cache) if cache

      @repositories ||= build_repositories(Geocoding::Cache.new)
    end

    # @param cache [Geocoding::Cache, nil] explicit cache bypasses memoization;
    #   omit (or pass nil) for the default memoized path.
    # @return [Array<Hash>]
    def repositories_json(cache: nil)
      return repositories(cache: cache).map(&:to_h) if cache

      @repositories_json ||= repositories.map(&:to_h)
    end

    private

    def build_repositories(cache)
      repos = RepositoryQueries.facet_counts
      addresses = RepositoryQueries.addresses

      repos.filter_map do |repo|
        name = repo[:name]
        coords = if addresses[name].present?
                   cache.fetch(name)
                 else
                   Geocoding::Cache::BLANK
                 end
        Repository.new(
          name: name,
          slug: name.parameterize,
          count: repo[:count],
          records_url: records_url_for(name),
          **coords
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

    # @param path [Pathname]
    # @param struct_class [Class]
    # @return [Array]
    def load_yaml(path, struct_class)
      YAML.safe_load_file(path, symbolize_names: true)
          .map { |entry| struct_class.new(**entry.slice(*struct_class.members)) }
    rescue StandardError => e
      Rails.logger.warn "Homepage data file missing or malformed: #{path} - #{e.message}"
      []
    end
  end
end
