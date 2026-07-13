# frozen_string_literal: true

# Homepage data from YAML files, the database, and Solr.
#
# Featured collections are curated via the FeaturedCollection admin.
# Repository data is loaded from YAML for the regional partnership band.
module HomepageData
  REPOSITORIES_PATH = Rails.root.join('data/repositories.yml')

  Repository = Data.define(:name, :slug, :count, :lat, :lng)

  class << self
    MAX_GUIDES = 8

    # Staff-picked collections appear first, then random backfill from Solr.
    # At most MAX_GUIDES are returned; if more featured collections exist,
    # only the first MAX_GUIDES (by created_at) are shown.
    # @return [Array<FeaturedCollection>]
    def collection_guides
      featured = load_featured
      return featured if featured.length >= MAX_GUIDES

      backfill = fetch_backfill(featured)
      featured + build_backfill_guides(backfill)
    rescue StandardError => e
      Rails.logger.warn "HomepageData: backfill failed - #{e.class}: #{e.message}"
      featured
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

    def load_featured
      FeaturedCollection.order(:created_at).limit(MAX_GUIDES).to_a
    end

    def fetch_backfill(featured)
      titles = featured.map(&:title)
      needed = MAX_GUIDES - featured.length
      RepositoryQueries.random_titles(limit: needed + titles.length)
                       .reject { |b| titles.include?(b[:title]) }
                       .first(needed)
    end

    def build_backfill_guides(backfill)
      backfill.map { |b| FeaturedCollection.new(title: b[:title], repository: b[:repository]) }
    end

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
