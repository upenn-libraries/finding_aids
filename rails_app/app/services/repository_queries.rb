# frozen_string_literal: true

# Solr queries for repository data used in the admin form.
class RepositoryQueries
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
