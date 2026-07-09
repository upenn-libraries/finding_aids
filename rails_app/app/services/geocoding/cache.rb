# frozen_string_literal: true

module Geocoding
  # File-backed coordinate cache.
  #
  #   cache = Geocoding::Cache.new
  #   cache.store("HSP", lat: 39.94, lng: -75.15)
  #   cache.persist
  #
  # Each entry is a hash with +:lat+, +:lng+, and optionally +:_failed+ (true).
  # Failed geocodes are stored as { lat: nil, lng: nil, _failed: true } so
  # they are never retried on subsequent lookups.
  class Cache
    CACHEFILE = Rails.root.join('data/geocoder_cache.yml')
    FAILED    = { lat: nil, lng: nil, _failed: true }.freeze
    BLANK     = { lat: nil, lng: nil }.freeze

    # Lazily loads the geocoding cache from disk (YAML file).
    # Returns an empty hash when the file doesn't exist yet.
    #
    # @return [Hash{String => Hash}] repository name → coordinate data
    def load
      @load ||= begin
        File.open(CACHEFILE, File::RDONLY) do |f|
          f.flock(File::LOCK_SH)
          YAML.safe_load_file(CACHEFILE, permitted_classes: [Symbol], aliases: true) || {}
        end
      rescue Errno::ENOENT
        {}
      end
    end

    # @param name [String]
    # @param lat [Float, nil]
    # @param lng [Float, nil]
    # @param failed [Boolean]
    def store(name, lat: nil, lng: nil, failed: false)
      load[name] = failed ? FAILED.dup : { lat: lat, lng: lng }
    end

    # Atomic disk write via temp-file + rename.
    def persist
      FileUtils.mkdir_p(File.dirname(CACHEFILE))
      tmp = Pathname.new("#{CACHEFILE}.#{Process.pid}.tmp")
      File.write(tmp, Psych.dump(@load))
      File.rename(tmp, CACHEFILE)
    end
  end
end
