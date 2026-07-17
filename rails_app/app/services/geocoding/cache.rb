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

    # ── public query API ──────────────────────────────────────────────

    # @param name [String] repository name
    # @return [Hash, nil] the cached entry or nil
    delegate :[], to: :entries

    # @param name [String] repository name
    # @return [Boolean] true when a previously-failed entry exists
    def failed?(name)
      entries.dig(name, :_failed) == true
    end

    # @param name [String] repository name
    # @return [Boolean] true when a successfully-cached coordinate entry exists
    def cached?(name)
      entries.dig(name, :lat).present?
    end

    # Look up an entry from cache.  Returns the coordinate hash on success,
    # BLANK when the entry is missing or was previously recorded as failed.
    #
    # @param name [String] repository name
    # @return [Hash]
    def fetch(name)
      return self[name] if cached?(name)
      return BLANK if failed?(name)

      BLANK
    end

    # ── write API ─────────────────────────────────────────────────────

    # Store a successful geocode result.
    #
    # @param name [String]
    # @param lat  [Float]
    # @param lng  [Float]
    def store(name, lat:, lng:)
      @entries = entries.merge(name => { lat: lat, lng: lng })
    end

    # Record a failed geocode so it is never retried.
    #
    # @param name [String]
    def store_failure(name)
      @entries = entries.merge(name => FAILED.dup)
    end

    # Atomic disk write via tempfile + rename.
    #
    # @return [void]
    def persist
      FileUtils.mkdir_p(File.dirname(@path))
      Tempfile.create(['geocoder_cache', '.yml'], File.dirname(@path)) do |tmp|
        tmp.write(YAML.dump(@entries))
        tmp.close
        File.rename(tmp.path, @path)
      end
    end

    private

    # Lazily loads the geocoding cache from disk (YAML file).
    # Acquires a shared lock on the file, then reads from the locked handle.
    #
    # @return [Hash{String => Hash}] repository name → coordinate data
    def entries
      @entries ||= load_from_disk.freeze
    end

    # @return [Hash]
    def load_from_disk
      File.open(@path, File::RDONLY) do |f|
        f.flock(File::LOCK_SH)
        YAML.safe_load(f.read, permitted_classes: [Symbol], aliases: true) || {}
      end
    rescue Errno::ENOENT
      {}
    end
  end
end
