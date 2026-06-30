# frozen_string_literal: true

# Homepage data from Solr and the database.
#
# Collection guides are curated via the CollectionGuide admin.
module HomepageData
  class << self
    MAX_GUIDES = 8

    # Staff-picked collections appear first, then random backfill from Solr.
    # @return [Array<CollectionGuide>]
    def collection_guides
      spotlights = load_spotlights
      return spotlights if spotlights.length >= MAX_GUIDES

      backfill = fetch_backfill(spotlights)
      spotlights + build_backfill_guides(backfill)
    rescue StandardError => e
      Rails.logger.warn "HomepageData: backfill failed - #{e.class}: #{e.message}"
      spotlights
    end

    private

    def load_spotlights
      CollectionGuide.order(:created_at).limit(MAX_GUIDES).to_a
    end

    def fetch_backfill(spotlights)
      titles = spotlights.map(&:title)
      needed = MAX_GUIDES - spotlights.length
      RepositoryQueries.random_titles(limit: needed + titles.length)
                       .reject { |b| titles.include?(b[:title]) }
                       .first(needed)
    end

    def build_backfill_guides(backfill)
      backfill.map { |b| CollectionGuide.new(title: b[:title], repository: b[:repository]) }
    end
  end
end
