# frozen_string_literal: true

# Solr queries for repository data used on the homepage, for featured
# collection creation, and for FeaturedCollection model validation.
class RepositoryQueries
  SOLR_FIELD_REPOSITORY = 'repository_ssi'
  SOLR_FIELD_TITLE = 'title_tsi'
  SOLR_FIELD_ADDRESS = 'repository_address_ssi'
  TITLES_MAX_ROWS = 20_000

  class << self
    # @return [Array<Hash>] [{name:, count:}, ...] sorted by count descending
    def facet_counts
      repos = raw_facet_pairs.each_slice(2).filter_map do |name, count|
        { name: name, count: count.to_i } if count.to_i.positive?
      end
      repos.sort_by { |r| -r[:count] }
    end

    # Returns flattened [name, count, name, count, ...] from the Solr facet response.
    #
    # @return [Array<String>]
    def raw_facet_pairs
      response = connection.get('select', params: {
                                  q: '*:*',
                                  facet: 'true',
                                  'facet.field': SOLR_FIELD_REPOSITORY,
                                  'facet.limit': -1,
                                  rows: 0
                                })
      response.dig('facet_counts', 'facet_fields', SOLR_FIELD_REPOSITORY) || []
    end

    # Returns one representative address per repository.
    #
    # @return [Hash{String => String}] repository name => address string
    def addresses
      response = connection.get('select', params: {
                                  q: '*:*',
                                  rows: 100,
                                  group: 'true',
                                  'group.field': SOLR_FIELD_REPOSITORY,
                                  'group.limit': 1,
                                  fl: "#{SOLR_FIELD_REPOSITORY},#{SOLR_FIELD_ADDRESS}"
                                })
      (response.dig('grouped', SOLR_FIELD_REPOSITORY, 'groups') || []).each_with_object({}) do |group, hash|
        doc = group.dig('doclist', 'docs')&.first
        next unless doc

        name = doc[SOLR_FIELD_REPOSITORY]
        addr = doc[SOLR_FIELD_ADDRESS]
        hash[name] = addr if name && addr.present?
      end
    end

    # @param [String] record_id
    # @return [Hash, nil]
    def featured_collection_data_for(record_id:)
      response = connection.get('select', params: {
                                  q: "id:#{record_id}",
                                  fl: "#{SOLR_FIELD_REPOSITORY},#{SOLR_FIELD_TITLE}",
                                  rows: 1
                                })
      record = response.dig('response', 'docs')&.first

      return nil unless record

      { repository: record[SOLR_FIELD_REPOSITORY], title: record[SOLR_FIELD_TITLE] }
    end

    private

    # @return [RSolr::Client]
    def connection
      Blacklight.default_index.connection
    end
  end
end
