class SolrService
  attr_reader :solr

  def initialize
    @solr = RSolr.connect url: ENV['SOLR_URL']
  end

  def add_many(documents)
    solr.add documents
    solr.commit
  end

  def delete_by_ids(ids)
    solr.delete_by_id ids
    solr.commit
  end

  def delete_by_endpoint(endpoint)
    solr.delete_by_query "endpoint_ts:#{endpoint.slug}"
    solr.commit
  end

  def delete_all
    solr.delete_by_query '*:*'
    solr.commit
  end
end
