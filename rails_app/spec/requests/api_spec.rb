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
    get api_url
  end

  after do
    solr.delete_by_ids(documents.pluck(:id))
    solr.commit
  end

  context 'with endpoints' do
    let(:api_url) { endpoints_api_path }

    it 'returns a list of all extant endpoints with count and records link' do
      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end

  context 'with repositories' do
    let(:api_url) { repositories_api_path }

    it 'returns a list of all extant repositories with count and records link' do
      expect(data.first.keys).to include 'name', 'count', 'records_url'
      expect(data.first['records_url']).to include '.json'
    end
  end
end
