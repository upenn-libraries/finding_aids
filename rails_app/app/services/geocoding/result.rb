# frozen_string_literal: true

module Geocoding
  # Value object that represents a geocoding outcome.
  #
  #   Geocoding::Result.success(lat: 39.95, lng: -75.16)
  #   Geocoding::Result.failure
  #
  # Replaces the boolean +failed+ flag previously threaded through
  # Cache#store and Service#store_result.
  class Result
    attr_reader :lat, :lng

    def self.success(lat:, lng:)
      new(lat: lat, lng: lng, success: true)
    end

    def self.failure
      new(lat: nil, lng: nil, success: false)
    end

    def success?
      @success
    end

    private

    def initialize(lat:, lng:, success:)
      @lat = lat
      @lng = lng
      @success = success
    end
  end
end
