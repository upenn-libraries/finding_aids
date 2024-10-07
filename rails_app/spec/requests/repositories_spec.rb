# frozen_string_literal: true

require 'rails_helper'

describe 'JSON API for Endpoint and Repository index' do
  let(:solr) { SolrService.new }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:documents) do
    [attributes_for(:solr_document), attributes_for(:solr_document)]
  end

  before do
    solr.add_many documents: documents
    solr.commit
  end

  after do
    solr.delete_by_ids(documents.pluck(:id))
    solr.commit
  end

  describe '/repositories' do
    before { get repositories_api_path, headers: headers }

    it 'returns expected fields' do
      items = response.parsed_body
      expect(items.length).to eq 1
      keys = items.first.keys
      expect(keys).to include('name', 'count', 'records_url')
    end
  end

  describe '/endpoints' do
    before { get endpoints_api_path, headers: headers }

    it 'returns expected fields' do
      items = response.parsed_body
      expect(items.length).to eq 1
      keys = items.first.keys
      expect(keys).to include('name', 'count', 'records_url')
    end
  end
end
