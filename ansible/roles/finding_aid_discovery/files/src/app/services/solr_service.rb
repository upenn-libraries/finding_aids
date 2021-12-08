class SolrService
  attr_reader :solr

  ENDPOINT_SLUG_FIELD = 'endpoint_ts'

  def initialize
    @solr = RSolr.connect url: ENV['SOLR_URL']
  end

  # @param [Array[<Hash>]] documents
  # @param [TrueClass, FalseClass] commit
  def add_many(documents:, commit: true)
    solr.add documents
    solr.commit if commit
  end

  # @param [Array[<String>]] ids
  def delete_by_ids(ids)
    solr.delete_by_id ids
    solr.commit
  end

  # @param [Endpoint] endpoint
  def delete_by_endpoint(endpoint)
    solr.delete_by_query "#{ENDPOINT_SLUG_FIELD}:#{endpoint.slug}"
    solr.commit
  end

  def delete_all
    solr.delete_by_query '*:*'
    solr.commit
  end

  # @param [Endpoint] endpoint
  def find_ids_by_endpoint(endpoint)
    solr.get 'select', params: { fq: "#{ENDPOINT_SLUG_FIELD}:#{endpoint.slug}" }
  end
end
