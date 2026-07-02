# frozen_string_literal: true

module Geocoding
  # Orchestrates geocoding lookups and bulk refreshes.
  #
  # Reads from the cache for the request path; writes to the cache for the
  # background-job and rake-task paths.  Callers inject a +Cache+ so the
  # service is decoupled from file I/O and easily testable.
  #
  #   service = Geocoding::Service.new
  #   service.coordinates_for("Haverford", "370 Lancaster Ave, Haverford, PA")
  #   # => { lat: 40.0087, lng: -75.3068 }  (from cache, no API call)
  #
  #   service.refresh!("Haverford" => "370 Lancaster Ave, ...")
  #   # => geocodes uncached entries, writes to cache, returns count
  class Service
    NOMINATIM_DELAY = 1.1

    # @param cache    [Geocoding::Cache]
    # @param api_delay [Float] seconds to sleep between API calls (set to 0 in tests)
    def initialize(cache: Cache.new, api_delay: NOMINATIM_DELAY)
      @cache = cache
      @api_delay = api_delay
    end

    # Return cached coordinates or +nil+ for a repository.
    # Never calls the geocoding API — safe for the request path.
    #
    # @param name  [String] repository name
    # @param address [String, nil] raw address
    # @return [Hash]  +{ lat: Float, lng: Float }+ or +{ lat: nil, lng: nil }+
    def coordinates_for(name, address)
      return BLANK if address.blank?

      entry = @cache.load[name]
      return BLANK if entry&.dig(:_failed)
      return entry if entry&.dig(:lat)

      BLANK
    end

    # Geocode a single address via the configured lookup API.
    #
    # @param address [String]
    # @return [Hash, nil] +{ lat: Float, lng: Float }+ or +nil+ on failure
    def geocode(address)
      results = Geocoder.search(clean_address(address))
      sleep @api_delay
      best = results.first
      return { lat: best.latitude, lng: best.longitude } if best&.coordinates&.all?(&:present?)
    rescue StandardError => e
      Rails.logger.warn "Geocoding::Service: #{e.class}: #{e.message}"
      nil
    end

    # Clear the cache (delegates to +Cache#clear!+).
    def clear_cache!
      @cache.clear!
    end

    # Bulk-geocode all uncached (and not-yet-failed) addresses.
    # Skips blank addresses, cached successes, and cached failures.
    #
    # @param addresses [Hash{String => String}]  name → address
    # @yield [name, status, lat, lng] optional progress block (for rake-task UI)
    # @return [Integer] number of new geocodings
    def refresh!(addresses)
      processed = addresses.filter_map do |name, address|
        next if address.blank? || skip?(name)

        coords = geocode(address)
        if coords
          @cache.store(name, **coords)
        else
          @cache.store(name, failed: true)
        end

        yield name, coords ? :ok : :failed, coords&.dig(:lat), coords&.dig(:lng) if block_given?
        true
      end

      @cache.persist if processed.any?
      processed.size
    end

    BLANK = { lat: nil, lng: nil }.freeze

    private

    def skip?(name)
      entry = @cache.load[name]
      entry && (entry[:lat] || entry[:_failed])
    end

    def clean_address(address)
      address.gsub(/\(.*?\)/, '').gsub(/,\s*,/, ',').strip
    end
  end
end
