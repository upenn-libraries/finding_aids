class SolrService
  attr_reader :solr

  ENDPOINT_SLUG_FIELD = 'endpoint_tsi'

  def initialize
    @solr = RSolr.connect url: ENV['SOLR_URL']
  end

  # @param [Array[<Hash>]] documents
  def add_many(documents:)
    solr.add documents
  end

  # @param [Array[<String>]] ids
  def delete_by_ids(ids)
    solr.delete_by_id ids
  end

  # @param [Endpoint] endpoint
  def delete_by_endpoint(endpoint)
    solr.delete_by_query "#{ENDPOINT_SLUG_FIELD}:#{endpoint.slug}"
  end

  def delete_all
    solr.delete_by_query '*:*'
  end

  # NOTE: autocommit behavior should be relied upon for development/production
  #       solr behavior. this commit method should only be used with tests, to
  #       avoid waiting for solr's autocommit
  def commit
    solr.commit
  end

  # @param [Endpoint] endpoint
  # @return [Array<String>]
  def find_ids_by_endpoint(endpoint)
    resp = solr.get 'select', params: { fq: "#{ENDPOINT_SLUG_FIELD}:#{endpoint.slug}", fl: 'id' }
    resp.dig('response', 'docs')&.collect { |d| d['id'] }
  end
end
