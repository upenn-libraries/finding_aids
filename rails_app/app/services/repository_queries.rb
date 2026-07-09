# frozen_string_literal: true

# Solr queries for repository data used on the homepage.
class RepositoryQueries
  # @return [Array<Hash>] [{name:, count:}, ...] sorted by count descending
  def self.facet_counts
    repos = raw_facet_pairs.each_slice(2).filter_map do |name, count|
      { name: name, count: count.to_i } if count.to_i.positive?
    end
    repos.sort_by { |r| -r[:count] }
  end

  # Returns flattened [name, count, name, count, ...] from the Solr facet response.
  #
  # @return [Array<String>]
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

  # Returns one representative address per repository.
  #
  # @return [Hash{String => String}] repository name => address string
  def self.addresses
    response = connection.get('select', params: {
                                q: '*:*',
                                group: 'true',
                                'group.field': 'repository_ssi',
                                'group.limit': 1,
                                fl: 'repository_ssi,repository_address_ssi'
                              })
    (response.dig('grouped', 'repository_ssi', 'groups') || []).each_with_object({}) do |group, hash|
      doc = group.dig('doclist', 'docs')&.first
      next unless doc

      name = doc['repository_ssi']
      addr = doc['repository_address_ssi']
      hash[name] = addr if name && addr.present?
    end
  end

  def self.connection
    Blacklight.default_index.connection
  end
end
