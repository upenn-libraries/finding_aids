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
    # @return [Hash] +{ lat: Float, lng: Float }+ or +Cache::BLANK+
    def coordinates_for(name, address)
      return Cache::BLANK if address.blank? || @cache.failed?(name)

      @cache[name] || Cache::BLANK
    end

    # Geocode a single address via the configured lookup API.
    #
    # @param address [String]
    # @return [Geocoding::Result]
    def geocode(address)
      results = Geocoder.search(Geocoding::AddressCleaner.clean(address))
      sleep @api_delay
      best = results.first
      return Result.failure unless best&.coordinates&.all?(&:present?)

      Result.success(lat: best.latitude, lng: best.longitude)
    rescue StandardError => e
      Rails.logger.warn "Geocoding::Service: #{e.class}: #{e.message}"
      Result.failure
    end

    # Bulk-geocode all uncached addresses.
    # Skips blank addresses, already-cached successes, and previously failed lookups.
    #
    # @param addresses [Hash{String => String}] name → address
    # @yield [name, result] optional progress hook
    # @return [Integer] count of new geocodings performed
    def refresh!(addresses)
      pending = addresses.select { |name, address| needs_geocoding?(name, address) }
      pending.each do |name, address|
        result = geocode(address)
        apply_result(name, result)
        yield(name, result) if block_given?
      end

      @cache.persist if pending.any?
      pending.size
    end

    private

    # @return [Boolean] true when this entry should be sent to the geocoding API
    def needs_geocoding?(name, address)
      address.present? && !@cache.cached?(name) && !@cache.failed?(name)
    end

    # @param name [String]
    # @param result [Geocoding::Result]
    def apply_result(name, result)
      return @cache.store_failure(name) unless result.success?

      @cache.store(name, lat: result.lat, lng: result.lng)
    end
  end
end
