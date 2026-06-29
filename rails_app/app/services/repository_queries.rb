# frozen_string_literal: true

# Solr queries for repository data used on the homepage.
class RepositoryQueries
  # Live repository names and document counts from the repository_ssi facet,
  # sorted by count descending. Zero-count repositories are excluded.
  #
  # @return [Array<Hash>] [{name:, count:}, ...]
  def self.facet_counts
    repos = raw_facet_pairs.each_slice(2).filter_map do |name, count|
      { name: name, count: count.to_i } if count.to_i.positive?
    end
    repos.sort_by { |r| -r[:count] }
  end

  # Returns one representative address per repository using field collapsing.
  #
  # @return [Hash{String => String}] repository name => address string
  def self.addresses
    response = connection.get('select', params: {
                                q: '*:*',
                                fl: 'repository_ssi,repository_address_ssi',
                                group: 'true',
                                'group.field': 'repository_ssi',
                                'group.limit': 1,
                                rows: 100
                              })
    parse_groups(response)
  end

  # @param response [Hash] Solr grouped response
  # @return [Hash{String => String}] name => address
  def self.parse_groups(response)
    groups = response.dig('grouped', 'repository_ssi', 'groups') || []
    groups.each_with_object({}) do |group, hash|
      doc = group.dig('doclist', 'docs')&.first
      name = doc&.dig('repository_ssi')
      addr = doc&.dig('repository_address_ssi')
      hash[name] = addr if name && addr.present?
    end
  end

  # @return [Array] alternating [name, count, name, count, ...]
  def self.raw_facet_pairs
    response = connection.get('select', params: {
                                q: '*:*',
                                facet: 'true',
                                'facet.field': 'repository_ssi',
                                'facet.limit': -1,
                                rows: 0
                              })
    response.dig('facet_counts', 'facet_fields', 'repository_ssi') || []
  end

  # Collection titles grouped by repository name.
  #
  # @return [Hash{String => Array<String>}] repository name => sorted array of titles
  def self.titles_by_repository
    grouped = Hash.new { |h, k| h[k] = [] }
    titles_docs.each do |doc|
      repo = doc['repository_ssi']
      title = doc['title_tsi']
      grouped[repo] << title if repo.present? && title.present?
    end
    grouped.transform_values(&:sort!).sort.to_h
  end

  # @return [RSolr::Client]
  def self.connection
    Blacklight.default_index.connection
  end

  # @return [Array<Hash>] Solr documents with repository_ssi and title_tsi
  def self.titles_docs
    response = connection.get('select', params: {
                                q: '*:*',
                                fl: 'repository_ssi,title_tsi',
                                rows: 10_000
                              })
    response.dig('response', 'docs') || []
  end

  private_class_method :connection, :titles_docs
end
