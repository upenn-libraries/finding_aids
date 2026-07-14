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

  describe 'arrival highlighting (U2)' do
    context 'when visiting a record page with a query param' do
      it 'highlights the query term on the page' do
        visit solr_document_path(document_id, q: 'collection')

        # Verify data attribute is set
        el = find('.faa-guide-content')
        expect(el['data-search-highlight-query-value']).to eq('collection')

        # mark.js should have wrapped matches in <mark> elements
        expect(page).to have_css('mark.search-highlight', wait: 3)
      end
    end

    context 'when visiting a record page without a query param' do
      it 'mounts the controller without highlighting' do
        visit solr_document_path(document_id)

        expect(page).to have_css('.faa-guide-content[data-controller="search-highlight"]')
        expect(page).to have_no_css('mark.search-highlight')
      end
    end
  end
end
