# frozen_string_literal: true

require 'rails_helper'

describe 'Repositories JSON API' do
  let(:solr) { SolrService.new }
  let(:documents) do
    [attributes_for(:solr_document), attributes_for(:solr_document)]
  end

  before do
    solr.add_many documents: documents
    solr.commit
    get '/repositories.json', headers: { 'CONTENT_TYPE' => 'application/json' }
  end

  after do
    solr.delete_by_ids(documents.pluck(:id))
    solr.commit
  end

  it 'returns expected fields' do
    items = JSON.parse response.body
    expect(items.length).to eq 1
    keys = items.first.keys
    expect(keys).to include('value', 'url', 'hits')
  end
end
