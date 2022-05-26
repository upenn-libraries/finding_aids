# frozen_string_literal: true

require 'rails_helper'

describe SolrService do
  let(:solr) { described_class.new }

  def sample_documents(endpoint_slug, count = 2)
    (1..count).map do |_i|
      { id: Faker::File.unique.file_name,
        "#{SolrService::ENDPOINT_SLUG_FIELD}": endpoint_slug }
    end
  end

  before do
    solr.delete_all
    solr.commit
  end

  after do
    solr.delete_all
    solr.commit
  end

  describe '#find_ids_by_endpoint' do
    let(:endpoint) { build(:endpoint, :index_harvest) }
    let(:slug) { endpoint.slug }
    let(:endpoint_sample_documents) { sample_documents(slug) }

    before do
      solr.add_many documents: endpoint_sample_documents
      solr.add_many documents: sample_documents('dont-return-these')
      solr.commit
    end

    it "finds only the ID for an specified endpoint's records" do
      ids = solr.find_ids_by_endpoint slug
      expect(ids).to include(*endpoint_sample_documents.pluck(:id))
      expect(ids).not_to include(*sample_documents('dont-return-these').pluck(:id))
    end
  end
end
