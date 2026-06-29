# frozen_string_literal: true

# Homepage data from Solr and the database.
#
# Repository counts and addresses come from Solr; coordinates are geocoded.
# Collection guides are curated via the FeaturedCollection admin.
module HomepageData
  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  class << self
    # @return [Array<FeaturedCollection>]
    def collection_guides
      FeaturedCollection.active.limit(8).to_a
    end

    # @return [Array<Repository>]
    def repositories
      @repositories ||= fetch_repositories_from_solr
    end

    # @return [String]
    def repositories_json
      @repositories_json ||= repositories.map(&:to_h).to_json
    end

    # Clear memoized repository data so the next call re-fetches from Solr.
    # Call this after adding a new repository to the index.
    def reset!
      @repositories = nil
      @repositories_json = nil
    end

    private

    # @return [Array<Repository>]
    def fetch_repositories_from_solr
      repos = RepositoryQueries.facet_counts
      addresses = fetch_addresses

      repos.filter_map do |repo|
        coords = coordinates_for(repo[:name], addresses[repo[:name]])
        Repository.new(name: repo[:name], slug: repo[:name].parameterize,
                       count: repo[:count], **coords)
      end
    end

    # @return [Hash{String => String}]
    def fetch_addresses
      RepositoryQueries.addresses
    rescue StandardError => e
      Rails.logger.warn "HomepageData: address lookup failed — #{e.class}: #{e.message}"
      {}
    end

    # @param name [String]
    # @param address [String, nil]
    # @return [Hash]
    def coordinates_for(name, address)
      return nil_coordinates if address.blank?

      @coordinates_cache ||= {}
      @coordinates_cache[name] ||= geocode(address) || nil_coordinates
    rescue StandardError => e
      Rails.logger.warn "HomepageData: geocoding failed for #{name} — #{e.class}: #{e.message}"
      nil_coordinates
    end

    # @return [Hash]
    def nil_coordinates
      { lat: nil, lng: nil }
    end

    # @param address [String]
    # @return [Hash, nil]
    def geocode(address)
      results = Geocoder.search(address)
      best = results.first

      { lat: best.latitude, lng: best.longitude } if best&.coordinates&.all?(&:present?)
    end
  end
end
