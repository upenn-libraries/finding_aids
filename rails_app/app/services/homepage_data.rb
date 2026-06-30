# frozen_string_literal: true

# Homepage data from Solr and the database.
#
# Repository counts and addresses come from Solr; coordinates are geocoded.
# Collection guides are curated via the FeaturedCollection admin.
module HomepageData
  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  NIL_COORDS = { lat: nil, lng: nil }.freeze

  class << self
    MAX_GUIDES = 8

    # Staff-picked collections appear first, then random backfill from Solr.
    # @return [Array<FeaturedCollection>]
    def collection_guides
      spotlights = load_spotlights
      return spotlights if spotlights.length >= MAX_GUIDES

      backfill = fetch_backfill(spotlights)
      spotlights + build_backfill_guides(backfill)
    rescue StandardError => e
      Rails.logger.warn "HomepageData: backfill failed - #{e.class}: #{e.message}"
      spotlights
    end

    # @return [Array<Repository>]
    def repositories
      @repositories ||= fetch_repositories_from_solr
    end

    # @return [String]
    def repositories_json
      repositories.map(&:to_h).to_json
    end

    # Clear memoized repository data so the next call re-fetches from Solr.
    # Call this after adding a new repository to the index.
    def reset!
      @repositories = nil
    end
    private

    def load_spotlights
      FeaturedCollection.order(:created_at).limit(MAX_GUIDES).to_a
    end

    def fetch_backfill(spotlights)
      titles = spotlights.map(&:title)
      needed = MAX_GUIDES - spotlights.length
      RepositoryQueries.random_titles(limit: needed + titles.length)
        .reject { |b| titles.include?(b[:title]) }
        .first(needed)
    end

    def build_backfill_guides(backfill)
      backfill.map { |b| FeaturedCollection.new(title: b[:title], repository: b[:repository]) }
    end

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
      Rails.logger.warn "HomepageData: address lookup failed - #{e.class}: #{e.message}"
      {}
    end

    # @param name [String]
    # @param address [String, nil]
    # @return [Hash]
    def coordinates_for(name, address)
      return NIL_COORDS if address.blank?

      @coordinates_cache ||= {}
      @coordinates_cache[name] ||= geocode(address) || NIL_COORDS
    rescue StandardError => e
      Rails.logger.warn "HomepageData: geocoding failed for #{name} - #{e.class}: #{e.message}"
      NIL_COORDS
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
