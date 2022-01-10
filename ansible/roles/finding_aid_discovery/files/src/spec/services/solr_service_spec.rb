require 'rails_helper'

describe SolrService do
  let(:solr) { SolrService.new }

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
  describe '#find_ids_by_endpoint' do
    let(:endpoint) { FactoryBot.build(:endpoint, :index_harvest) }
    let(:endpoint_sample_documents) { sample_documents(endpoint.slug) }
    before do
      solr.add_many documents: endpoint_sample_documents
      solr.add_many documents: sample_documents('dont-return-these')
      solr.commit
    end
    it "finds only the ID for an specified endpoint's records" do
      ids = solr.find_ids_by_endpoint endpoint
      expect(ids).to include(*endpoint_sample_documents.collect { |d| d[:id] })
      expect(ids).not_to include(*sample_documents('dont-return-these').collect { |d| d[:id] })
    end
  end
  after do
    solr.delete_all
    solr.commit
  end
end
