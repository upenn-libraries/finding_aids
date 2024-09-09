# frozen_string_literal: true

class SolrService
  attr_reader :solr

  ENDPOINT_SLUG_FIELD = 'endpoint_ssi'
  LEGACY_ID_FIELD = 'legacy_ids_ssim'

  def initialize
    @solr = RSolr.connect url: ENV.fetch('SOLR_URL')
  end

  # @param [String] legacy_id
  # @return [String, nil]
  def find_id_by_legacy_id(legacy_id)
    resp = solr.get 'select', params: { fq: "#{LEGACY_ID_FIELD}:#{legacy_id.upcase}", fl: 'id', rows: 1 }
    return resp.dig('response', 'docs')[0]['id'] if resp.dig('response', 'docs')&.any?

    nil
  end

  # @param [Array[<Hash>]] documents
  def add_many(documents:)
    solr.add documents
  end

  # @param [Array[<String>]] ids
  def delete_by_ids(ids)
    solr.delete_by_id ids
  end

  # @param [String] endpoint_slug
  def delete_by_endpoint(endpoint_slug)
    solr.delete_by_query "#{ENDPOINT_SLUG_FIELD}:#{endpoint_slug}"
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

  # Query for all documents related to an endpoint.
  #
  # @param [String] slug
  # @return [Array<String>]
  def find_ids_by_endpoint(slug)
    resp = solr.get 'select', params: { fq: "#{ENDPOINT_SLUG_FIELD}:#{slug}", fl: 'id', rows: 100_000 }
    resp.dig('response', 'docs')&.collect { |d| d['id'] }
  end
end
