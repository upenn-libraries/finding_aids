# frozen_string_literal: true

require 'rails_helper'

describe 'API index endpoints' do
  let(:data) { response.parsed_body }
  let(:solr) { SolrService.new }

  def seed_solr(records)
    solr.add_many documents: records
    solr.commit
  end

  def cleanup_solr(records)
    solr.delete_by_ids(records.pluck(:id))
    solr.commit
  end

  context 'with endpoints' do
    let(:api_documents) do
      [attributes_for(:solr_document, endpoint_ssi: 'endpoint1'),
       attributes_for(:solr_document, endpoint_ssi: 'endpoint2'),
       attributes_for(:solr_document, endpoint_ssi: 'endpoint2',
                                      repository_name_component_1_ssi: 'A',
                                      repository_name_component_2_ssi: 'B',
                                      repository_name_component_3_ssi: 'C')]
    end

    before { seed_solr(api_documents) }
    after  { cleanup_solr(api_documents) }

    it 'returns a list of all extant endpoints with count and records link' do
      get endpoints_api_path

      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end

  context 'with repositories' do
    let(:api_documents) do
      [attributes_for(:solr_document, endpoint_ssi: 'endpoint1'),
       attributes_for(:solr_document, endpoint_ssi: 'endpoint2'),
       attributes_for(:solr_document, endpoint_ssi: 'endpoint2',
                                      repository_name_component_1_ssi: 'A',
                                      repository_name_component_2_ssi: 'B',
                                      repository_name_component_3_ssi: 'C')]
    end

    before { seed_solr(api_documents) }
    after  { cleanup_solr(api_documents) }

    it 'returns a list of all extant repositories with count and records link' do
      get repositories_api_path

      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end

  context 'with map_data' do
    let(:cache) { Geocoding::Cache.new }
    let(:cached_coords) { { lat: 39.98, lng: -75.19 } }

    before do
      allow(Geocoding::Cache).to receive(:new).and_return(cache)
      HomepageData.instance_variable_set(:@repositories, nil)
      HomepageData.instance_variable_set(:@repositories_json, nil)
    end

    context 'when a repository has cached coordinates' do
      before do
        cache.store('Test Repo', **cached_coords)
        allow(RepositoryQueries).to receive_messages(
          facet_counts: [{ name: 'Test Repo', count: 100 }],
          addresses: { 'Test Repo' => '1 Research Park' }
        )
        get map_data_api_path
      end

      it 'returns the coordinates so markers render on the map' do
        expect(data.first['lat']).to eq(cached_coords[:lat])
        expect(data.first['lng']).to eq(cached_coords[:lng])
      end
    end

    context 'when a repository has no cached coordinates' do
      before do
        allow(RepositoryQueries).to receive_messages(
          facet_counts: [{ name: 'Uncached Repo', count: 50 }],
          addresses: { 'Uncached Repo' => '456 Unknown St' }
        )
        get map_data_api_path
      end

      it 'returns null coordinates (no marker on the map)' do
        expect(data.first['lat']).to be_nil
        expect(data.first['lng']).to be_nil
      end
    end

    it 'returns repository data with expected keys' do
      cache.store('Test Repo', **cached_coords)
      allow(RepositoryQueries).to receive_messages(
        facet_counts: [{ name: 'Test Repo', count: 100 }],
        addresses: { 'Test Repo' => '1 Research Park' }
      )
      get map_data_api_path

      expect(data.first.keys).to include 'name', 'slug', 'count', 'lat', 'lng'
    end
  end

  context 'with real Solr documents (end-to-end)' do
    let(:cache) { Geocoding::Cache.new }
    let(:e2e_coords) { { lat: 40.01, lng: -75.01 } }
    let(:e2e_docs) do
      [attributes_for(:solr_document,
                      repository_ssi: 'Mapped Repo',
                      repository_address_ssi: '123 Main St, Philadelphia, PA'),
       attributes_for(:solr_document,
                      repository_ssi: 'Addrless Repo',
                      repository_address_ssi: nil)]
    end

    before do
      allow(Geocoding::Cache).to receive(:new).and_return(cache)
      HomepageData.instance_variable_set(:@repositories, nil)
      HomepageData.instance_variable_set(:@repositories_json, nil)
      seed_solr(e2e_docs)
      cache.store('Mapped Repo', **e2e_coords)
      get map_data_api_path
    end

    after { cleanup_solr(e2e_docs) }

    it 'returns coordinates for repos with cached data' do
      mapped = data.find { |r| r['name'] == 'Mapped Repo' }
      expect(mapped['lat']).to eq(e2e_coords[:lat])
      expect(mapped['lng']).to eq(e2e_coords[:lng])
    end

    it 'returns null coordinates for repos without cached data' do
      addrless = data.find { |r| r['name'] == 'Addrless Repo' }
      expect(addrless['lat']).to be_nil
      expect(addrless['lng']).to be_nil
    end
  end
end
