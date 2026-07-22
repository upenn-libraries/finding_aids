# frozen_string_literal: true

# Shared request-spec helpers for seeding and tearing down Solr documents.
# Included for `type: :request` specs in `spec/rails_helper.rb`, so it is
# available to the API specs and any future `repositories_spec`.
module SolrHelpers
  # @return [SolrService]
  def solr
    @solr ||= SolrService.new
  end

  # @param records [Array<Hash>] documents to add to the index
  def seed_solr(records)
    solr.add_many documents: records
    solr.commit
  end

  # @param records [Array<Hash>] documents to remove from the index
  def cleanup_solr(records)
    solr.delete_by_ids(records.pluck(:id))
    solr.commit
  end
end
