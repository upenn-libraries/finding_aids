# frozen_string_literal: true

# Homepage data from YAML files, the database, and Solr.
#
# Featured collections are curated via the FeaturedCollection admin.
# Repository data is loaded from YAML for the regional partnership band.
module HomepageData
  REPOSITORIES_PATH = Rails.root.join('data/repositories.yml')
  MAX_GUIDES = 8

  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  class << self
    # Staff-picked collections shown on the homepage, up to MAX_GUIDES.
    # @return [Array<FeaturedCollection>]
    def collection_guides
      FeaturedCollection.order(:created_at).limit(MAX_GUIDES).to_a
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
