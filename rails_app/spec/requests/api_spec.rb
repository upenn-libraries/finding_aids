# frozen_string_literal: true

require 'rails_helper'

describe 'API index endpoints' do
  let(:data) { response.parsed_body }
  let(:solr) { SolrService.new }
  let(:documents) do
    [attributes_for(:solr_document, endpoint_ssi: 'endpoint1'),
     attributes_for(:solr_document, endpoint_ssi: 'endpoint2'),
     attributes_for(:solr_document, endpoint_ssi: 'endpoint2',
                                    repository_name_component_1_ssi: 'A',
                                    repository_name_component_2_ssi: 'B',
                                    repository_name_component_3_ssi: 'C')]
  end

  before do
    solr.add_many documents: documents
    solr.commit
  end

  after do
    solr.delete_by_ids(documents.pluck(:id))
    solr.commit
  end

  context 'with endpoints' do
    before { get endpoints_api_path }

    it 'returns a list of all extant endpoints with count and records link' do
      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end

  context 'with repositories' do
    before { get repositories_api_path }

    it 'returns a list of all extant repositories with count and records link' do
      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end

  context 'with map_data' do
    let!(:geo_service) { Geocoding::Service.new(cache: cache, api_delay: 0) }
    let(:cache) { Geocoding::Cache.new }

    before do
      cache.store('Test Repo', lat: 39.98, lng: -75.19)
      HomepageData.geocoding_service = geo_service
      HomepageData.reset!
      allow(RepositoryQueries).to receive_messages(
        facet_counts: [{ name: 'Test Repo', count: 100 }],
        addresses: { 'Test Repo' => '1 Research Park' }
      )
      get map_data_api_path
    end

    it 'returns repository data with coordinates for the map' do
      expect(data.first.keys).to include 'name', 'slug', 'count', 'lat', 'lng'
      expect(data.first['lat']).to eq(39.98)
    end
  end
end
