# frozen_string_literal: true

require 'tempfile'

module Geocoding
  # File-backed coordinate cache.
  #
  #   cache = Geocoding::Cache.new
  #   cache.store("HSP", lat: 39.94, lng: -75.15)
  #   cache.store_failure("NotFound")
  #   cache.persist
  #
  # Each entry is a hash with +:lat+, +:lng+, and optionally +:_failed+ (true).
  # Failed geocodes are stored as { lat: nil, lng: nil, _failed: true } so
  # they are never retried on subsequent lookups.
  class Cache
    CACHEFILE = Rails.root.join('data/geocoder_cache.yml')
    FAILED    = { lat: nil, lng: nil, _failed: true }.freeze
    BLANK     = { lat: nil, lng: nil }.freeze

    attr_reader :path

    # @param path [Pathname, String] override cache file location (used in tests)
    def initialize(path: CACHEFILE)
      @path = Pathname.new(path)
    end

    # @param name [String] repository name
    # @return [Hash, nil] the cached entry or nil
    delegate :[], to: :entries

    # Store a successful geocode result.
    #
    # @param name [String]
    # @param lat [Float]
    # @param lng [Float]
    def store(name:, lat:, lng:)
      @entries = entries.merge(name => { lat: lat, lng: lng })
    end

    # Record a failed geocode so it is never retried.
    #
    # @param name [String]
    def store_failure(name)
      @entries = entries.merge(name => FAILED.dup)
    end

    # Disk write via tempfile + rename.
    #
    # @return [nil]
    def persist
      FileUtils.mkdir_p(File.dirname(@path))
      Tempfile.create(['geocoder_cache', '.yml'], File.dirname(@path)) do |tmp|
        tmp.write(YAML.dump(@entries))
        tmp.close
        File.rename(tmp.path, @path)
      end
    end

    # Clear all in-memory entries without touching disk.
    # Used to reset the cache between tests.
    #
    # @return [void]
    def clear!
      @entries = {}
    end

    # Lazily loads the geocoding cache from disk (YAML file).
    #
    # @return [Hash{String => Hash}] repository name → coordinate data
    def entries
      @entries ||= load_from_disk.freeze
    end

    private

    # @return [Hash]
    def load_from_disk
      File.open(@path, File::RDONLY) do |f|
        YAML.safe_load(f.read, permitted_classes: [Symbol], aliases: true) || {}
      end
    rescue Errno::ENOENT
      {}
    end
  end
end
