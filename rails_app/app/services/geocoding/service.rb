# frozen_string_literal: true

module Geocoding
  # Orchestrates geocoding lookups and bulk refreshes.
  #
  #   service = Geocoding::Service.new
  #   service.geocode("Haverford", "370 Lancaster Ave, Haverford, PA")
  #   # => { lat: 40.0087, lng: -75.3068 } (via API call)
  #
  #   service.refresh!("Haverford" => "370 Lancaster Ave, ...")
  #   # => geocodes entries, writes to cache, returns count
  class Service
    NOMINATIM_DELAY = 1.1

    # @param cache [Geocoding::Cache]
    # @param api_delay [Float] seconds to sleep between API calls (set to 0 in tests)
    def initialize(cache: Cache.new, api_delay: NOMINATIM_DELAY)
      @cache = cache
      @api_delay = api_delay
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

    # Bulk-geocode all addresses and persist to cache file.
    #
    # @param addresses [Hash{String => String}] name → address
    # @yield [name, result] optional progress hook
    # @return [Integer] count of addresses considered
    def run!(addresses)
      addresses.each do |name, address|
        next if address.empty?

        result = geocode(address)
        apply_result(name, result)
        yield(name, result) if block_given?
      end

      @cache.persist
      addresses.size
    end

    private

    # @return [Boolean] true when this entry should be sent to the geocoding API
    def needs_geocoding?(name, address)
      address.present? && !@cache.failed?(name)
    end

    # @param name [String]
    # @param result [Geocoding::Result]
    def apply_result(name, result)
      return @cache.store_failure(name) unless result.success?

      @cache.store(name, lat: result.lat, lng: result.lng)
    end
  end
end
