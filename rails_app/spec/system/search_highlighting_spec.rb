# frozen_string_literal: true

require 'system_helper'

describe 'Search highlighting on record pages' do
  let(:solr) { SolrService.new }
  let(:document_hash) { attributes_for(:solr_document, :with_collection_data) }
  let(:document_id) { document_hash[:id] }

  before do
    solr.add_many documents: [document_hash]
    solr.commit
  end

  after do
    solr.delete_by_endpoint 'test-endpoint'
    solr.commit
  end

  describe 'arrival highlighting (U1 skeleton)' do
    context 'when visiting a record page without a query param' do
      it 'mounts the search-highlight Stimulus controller on the guide content' do
        visit solr_document_path(document_id)

        expect(page).to have_css('.faa-guide-content[data-controller="search-highlight"]')
        expect(page).to have_css('.faa-guide-content[data-search-highlight-target="context"]')
      end
    end
  end
end
