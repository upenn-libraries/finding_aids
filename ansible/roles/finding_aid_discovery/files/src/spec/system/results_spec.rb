# frozen_string_literal: true

require 'system_helper'

describe 'Blacklight search results' do
  context 'with no records in the index' do
    before do
      visit search_catalog_path search_field: 'all_fields', q: ''
    end

    it 'shows the designated message' do
      expect(page).to have_text I18n.t('blacklight.search.zero_results.title')
    end
  end

  context 'with a record' do
    let(:solr) { SolrService.new }
    let(:document_hash) { attributes_for(:solr_document, :with_collection_data) }
    let(:document_title) { document_hash[:title_tsi] }

    before do
      solr.add_many documents: [document_hash]
      solr.commit
    end

    after do
      solr.delete_by_endpoint 'test-endpoint'
      solr.commit
    end

    it 'shows a result' do
      visit search_catalog_path search_field: 'all_fields', q: ''
      expect(page).to have_css 'article.document-position-1'
    end

    it 'returns a record when searching by identifier' do
      visit search_catalog_path search_field: 'all_fields', q: document_hash[:unit_id_tsi]
      expect(page).to have_css 'article.document-position-1 h3',
                               text: /#{document_title}/
    end

    it 'returns a record when searching by title' do
      visit search_catalog_path search_field: 'all_fields', q: document_title
      expect(page).to have_css 'article.document-position-1 h3',
                               text: /#{document_title}/
    end

    it 'returns a record when searching by collection information' do
      visit search_catalog_path search_field: 'all_fields', q: 'Something Really Distinctive'
      expect(page).to have_css 'article.document-position-1 h3',
                               text: /#{document_title}/
    end
  end
end
