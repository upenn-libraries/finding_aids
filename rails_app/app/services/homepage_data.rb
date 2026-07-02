# frozen_string_literal: true

require 'cgi'

# Homepage data from YAML and Solr.
#
# Repository coordinates are geocoded via Nominatim and cached to disk.
# refresh_coordinates! is called after harvest to keep them current.
# Collection guides are loaded from YAML.
module HomepageData
  COLLECTION_GUIDES_PATH = Rails.root.join('data/collection_guides.yml')

  CollectionGuide = Data.define(:identifier, :name, :collection)
  Repository = Data.define(:name, :slug, :count, :lat, :lng, :records_url)

  NIL_COORDS = { lat: nil, lng: nil }.freeze
  CACHEFILE = Rails.root.join('tmp/geocoder_cache.yml')

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
          coords = coordinates_for(repo[:name], addresses[repo[:name]])
          records_url = "/records?f%5Brepository_ssi%5D%5B%5D=#{CGI.escape(repo[:name])}"
          Repository.new(name: repo[:name], slug: repo[:name].parameterize,
                         count: repo[:count], records_url: records_url, **coords)
        end
      end
    end

    # @return [String]
    def repositories_json
      repositories.map(&:to_h).to_json
    end

    # Clear memoized repository data so the next call re-fetches from Solr.
    # Call this after adding a new repository to the index.
    def reset!
      @repositories = nil
      @coordinates = nil
    end

    def refresh_coordinates!
      cache = load_coordinates
      addresses = RepositoryQueries.addresses
      updated = false

      addresses.each do |name, address|
        next if address.blank? || (cache.key?(name) && cache[name][:lat])

        clean = address.gsub(/\(.*?\)/, '').gsub(/,\s*,/, ',').strip
        results = Geocoder.search(clean)
        best = results.first
        cache[name] = if best&.coordinates&.all?(&:present?)
                        { lat: best.latitude, lng: best.longitude }
                      else
                        NIL_COORDS
                      end
        updated = true
      rescue StandardError => e
        Rails.logger.warn "HomepageData: geocoding failed for #{name} - #{e.class}: #{e.message}"
      end

      persist_coordinates(cache) if updated
      @coordinates = cache
    end

    private

    def coordinates_for(name, address)
      return NIL_COORDS if address.blank?

      cache = load_coordinates
      return cache[name] if cache.key?(name) && cache[name][:lat]

      # Fall back to live geocoder (uses Rails.cache internally)
      coords = geocode(address) || NIL_COORDS
      cache[name] = coords
      persist_coordinates(cache)
      coords
    rescue StandardError => e
      Rails.logger.warn "HomepageData: geocoding failed for #{name} - #{e.class}: #{e.message}"
      NIL_COORDS
    end

    def geocode(address)
      results = Geocoder.search(address)
      best = results.first
      { lat: best.latitude, lng: best.longitude } if best&.coordinates&.all?(&:present?)
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

    def load_coordinates
      @coordinates ||= if File.exist?(CACHEFILE)
                         YAML.safe_load_file(CACHEFILE, permitted_classes: [Symbol], aliases: true) || {}
                       else
                         {}
                       end
    end

    def persist_coordinates(cache)
      FileUtils.mkdir_p(File.dirname(CACHEFILE))
      File.write(CACHEFILE, Psych.dump(cache))
    end
  end
end
