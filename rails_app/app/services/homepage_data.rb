# frozen_string_literal: true

# Loads and caches homepage data from YAML files.
#
# YAML is parsed once per process via memoized module-level instance variables,
# not on every request.
module HomepageData
  COLLECTION_GUIDES_PATH = Rails.root.join('data/collection_guides.yml')
  REPOSITORIES_PATH      = Rails.root.join('data/repositories.yml')

  CollectionGuide = Data.define(:identifier, :name, :collection)
  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  class << self
    # @return [Array<CollectionGuide>]
    def collection_guides
      @collection_guides ||= load_yaml(COLLECTION_GUIDES_PATH, CollectionGuide)
    end

    # @return [Array<Repository>]
    def repositories
      @repositories ||= load_yaml(REPOSITORIES_PATH, Repository)
    end

    # @return [String] pre-serialized JSON of repository data for Stimulus data attributes
    def repositories_json
      @repositories_json ||= repositories.map(&:to_h).to_json
    end

    private

    # Parses a YAML file and wraps each entry in the given Data class.
    # Returns an empty array and logs a warning if the file is missing or malformed.
    #
    # @param path [Pathname] absolute path to the YAML file
    # @param struct_class [Class] a +Data.define+ class whose members match the YAML keys
    # @return [Array]
    def load_yaml(path, struct_class)
      YAML.safe_load_file(path, symbolize_names: true)
          .map { |entry| struct_class.new(**entry.slice(*struct_class.members)) }
    rescue Errno::ENOENT, Psych::SyntaxError, ArgumentError => e
      Rails.logger.warn "Homepage data file missing or malformed: #{path} — #{e.message}"
      []
    end
  end
end
