# frozen_string_literal: true

module Geocoding
  # Value object that represents a geocoding outcome.
  #
  #   Geocoding::Result.success(lat: 39.95, lng: -75.16)
  #   Geocoding::Result.failure
  #
  class Result
    attr_reader :lat, :lng

    # @param lat [Float]
    # @param lng [Float]
    # @return [Geocoding::Result]
    def self.success(lat:, lng:)
      new(lat: lat, lng: lng, success: true)
    end

    # @return [Geocoding::Result]
    def self.failure
      new(lat: nil, lng: nil, success: false)
    end

    # @return [Boolean]
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
