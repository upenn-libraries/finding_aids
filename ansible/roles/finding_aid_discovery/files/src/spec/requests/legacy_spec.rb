# frozen_string_literal: true

require 'rails_helper'

describe 'Legacy identifier redirection' do
  context 'without the identifier in the index' do
    it 'returns a 404' do
      get '/records/legacy/not-a-valid-legacy-id'
      expect(response.code).to eq '404'
    end
  end

  context 'with the identifier in the index' do
    let(:solr) { SolrService.new }
    let(:document_hash) { attributes_for :solr_document }

    before do
      solr.add_many documents: [document_hash]
      solr.commit
    end

    after do
      solr.delete_by_endpoint 'test-endpoint'
      solr.commit
    end

    it 'redirects to show page' do
      get "/records/legacy/#{document_hash[:legacy_ids_ssim].first}"
      expect(response).to have_http_status :permanent_redirect
      expect(response).to redirect_to(solr_document_url(document_hash[:id]))
    end
  end
end
