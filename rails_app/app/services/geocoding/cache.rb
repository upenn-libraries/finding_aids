# frozen_string_literal: true

module Geocoding
  # File-backed coordinate cache.
  #
  #   cache = Geocoding::Cache.new
  #   cache["Haverford"]   # => { lat: 40.00, lng: -75.30 }
  #   cache.store("HSP", lat: 39.94, lng: -75.15)
  #   cache.persist
  #   cache.clear!
  #
  # Each entry is a hash with +:lat+, +:lng+, and optionally +:_failed+ (true).
  # Failed geocodes are stored as { lat: nil, lng: nil, _failed: true } so
  # they are never retried on subsequent lookups.
  class Cache
    CACHEFILE = Rails.root.join('tmp/geocoder_cache.yml')
    FAILED    = { lat: nil, lng: nil, _failed: true }.freeze
    BLANK     = { lat: nil, lng: nil }.freeze

    # @return [Hash{String => Hash}]
    def load
      @data ||= begin
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
      File.write(tmp, Psych.dump(@data))
      File.rename(tmp, CACHEFILE)
    end

    # Clear in-memory data and delete the file.
    def clear!
      @data = {}
      File.delete(CACHEFILE) if File.exist?(CACHEFILE)
    end
  end
end
