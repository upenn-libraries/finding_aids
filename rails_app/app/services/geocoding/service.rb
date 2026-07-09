# frozen_string_literal: true

module Geocoding
  # Orchestrates geocoding lookups and bulk refreshes.
  #
  #   service = Geocoding::Service.new
  #   service.coordinates_for("Haverford", "370 Lancaster Ave, Haverford, PA")
  #   # => { lat: 40.0087, lng: -75.3068 }  (from cache, no API call)
  #
  #   service.refresh!("Haverford" => "370 Lancaster Ave, ...")
  #   # => geocodes uncached entries, writes to cache, returns count
  class Service
    NOMINATIM_DELAY = 1.1
    BLANK = { lat: nil, lng: nil }.freeze

    # @param cache     [Geocoding::Cache]
    # @param api_delay [Float] seconds to sleep between API calls (set to 0 in tests)
    def initialize(cache: Cache.new, api_delay: NOMINATIM_DELAY)
      @cache = cache
      @api_delay = api_delay
    end

    # Return cached coordinates or blank for a repository.
    # Never calls the geocoding API — safe for the request path.
    #
    # @param name    [String] repository name
    # @param address [String, nil] raw address
    # @return [Hash] +{ lat: Float, lng: Float }+ or +BLANK+
    def coordinates_for(name, address)
      return BLANK if address.blank?

      entry = @cache.load[name]
      return BLANK if entry && (entry[:lat].nil? || entry[:_failed])
      return entry if entry&.dig(:lat)

      BLANK
    end

    # Geocode a single address via the configured lookup API.
    #
    # @param address [String]
    # @return [Hash, nil] +{ lat: Float, lng: Float }+ or +nil+ on failure
    def geocode(address)
      results = Geocoder.search(Geocoding::AddressCleaner.clean(address))
      sleep @api_delay
      best = results.first
      { lat: best.latitude, lng: best.longitude } if best&.coordinates&.all?(&:present?)
    rescue StandardError => e
      Rails.logger.warn "Geocoding::Service: #{e.class}: #{e.message}"
      nil
    end

    # Bulk-geocode all uncached addresses.
    # Skips blank addresses, already-cached successes, and previously failed lookups.
    #
    # @param addresses [Hash{String => String}] name → address
    # @yield [name, status, lat, lng] optional progress hook
    # @return [Integer] count of new geocodings performed
    def refresh!(addresses) # rubocop:disable Metrics/CyclomaticComplexity
      processed = addresses.filter_map do |name, address|
        next if address.blank? || already_cached?(name)

        coords = geocode(address)
        store_result(name, coords)
        yield name, coords ? :ok : :failed, coords&.dig(:lat), coords&.dig(:lng) if block_given?
        true
      end

      @cache.persist if processed.any?
      processed.size
    end

    private

    # @param name [String] repository name
    # @return [Boolean] true when the entry has coordinates or a prior failure
    def already_cached?(name)
      entry = @cache.load[name]
      entry && (entry[:lat] || entry[:_failed])
    end

    # @param name [String] repository name
    # @param coords [Hash, nil] geocoded coordinates or nil on failure
    def store_result(name, coords)
      return @cache.store(name, failed: true) unless coords

      @cache.store(name, **coords)
    end
  end
end
