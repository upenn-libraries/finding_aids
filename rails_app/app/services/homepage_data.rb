# frozen_string_literal: true

# Homepage data from YAML and Solr.
#
# Repository coordinates are looked up from the Geocoding::Service cache.
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

    # @return [Array<Repository>]
    def repositories
      @repositories ||= begin
        repos = RepositoryQueries.facet_counts
        addresses = RepositoryQueries.addresses

        repos.filter_map do |repo|
          coords = geocoding_service.coordinates_for(repo[:name], addresses[repo[:name]])
          Repository.new(
            name: repo[:name],
            slug: repo[:name].parameterize,
            count: repo[:count],
            records_url: records_url_for(repo[:name]),
            **coords
          )
        end
      end
    end

    # @return [Array<Hash>]
    def repositories_json
      @repositories_json ||= repositories.map(&:to_h)
    end

    attr_writer :geocoding_service

    private

    def geocoding_service
      @geocoding_service ||= Geocoding::Service.new
    end

    # @param name [String] repository name
    # @return [String] URL to filtered records page
    def records_url_for(name)
      "/records?f%5Brepository_ssi%5D%5B%5D=#{CGI.escape(name)}"
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
