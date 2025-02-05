# frozen_string_literal: true

require 'rails_helper'

describe 'Catalog actions' do
  describe 'UPenn vanity route' do
    it 'routes to the search results with the penn source facet applied' do
      get upenn_path
      expect(response).to redirect_to search_catalog_path({ 'f[record_source][]': 'upenn' })
    end
  end

  describe 'JSON API' do
    let(:data) { response.parsed_body }
    let(:solr) { SolrService.new }
    let(:documents) { [attributes_for(:solr_document)] }

    before do
      solr.add_many documents: documents
      solr.commit
    end

    describe 'index endpoint' do
      before { get search_catalog_path, headers: { 'HTTP_ACCEPT' => 'application/json' } }

      it 'returns the expected attributes' do
        expected_keys = %w[title extent_ssim display_date_ssim genre_form_ssim creators_ssim
                           abstract_scope_contents_tsi]
        expect(data['data'].first['attributes'].keys).to include(*expected_keys)
      end
    end
  end
end
