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

    # Collection titles grouped by repository name.
    #
    # @return [Hash{String => Array<String>}] repository name => sorted array of titles
    def titles_by_repository
      valid_title_pairs
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last).sort }
        .sort
        .to_h
    end

    private

    # @return [RSolr::Client]
    def connection
      Blacklight.default_index.connection
    end

    # @return [Array<Hash>] Solr documents with repository_ssi and title_tsi
    def titles_docs
      response = connection.get('select', params: {
                                  q: '*:*',
                                  fl: "#{SOLR_FIELD_REPOSITORY},#{SOLR_FIELD_TITLE}",
                                  rows: TITLES_MAX_ROWS
                                })
      response.dig('response', 'docs') || []
    end

    # @return [Array<Array(String, String)>] [[repo, title], ...] pairs with both present
    def valid_title_pairs
      titles_docs.filter_map do |doc|
        repo = doc[SOLR_FIELD_REPOSITORY]
        title = doc[SOLR_FIELD_TITLE]
        [repo, title] if repo.present? && title.present?
      end
    end
  end
end
