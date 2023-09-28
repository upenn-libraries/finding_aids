# frozen_string_literal: true

require 'system_helper'

describe 'Requests form' do
  let(:solr) { SolrService.new }
  let(:document_hash) { attributes_for(:solr_document, :requestable, :with_collection_data) }
  let(:document_title) { document_hash[:title_tsi] }

  # Index a requestale record
  before do
    solr.add_many documents: [document_hash]
    solr.commit
    visit solr_document_path(document_hash[:id])
  end

  after do
    solr.delete_by_endpoint 'test-endpoint'
    solr.commit
  end

  context 'with a single container available' do
    it 'the page includes a request checkbox' do
      expect(page).to have_field 'c[Box_1_111111111]', visible: :hidden
      expect(page).to have_field 'c[Box_2_222222222]', visible: :hidden
    end

    context 'when confirming the request' do
      before do
        check 'c[Box_1_111111111]', visible: false
        check 'c[Box_2_222222222]', visible: false
        click_button 'Request'
      end

      it 'takes user to PennKey login page' do
        click_button I18n.t('requests.form.fields.submit')
        expect(page).to have_text 'PennKey'
      end

      it 'takes user to Aeon login page' do
        choose I18n.t('requests.form.fields.external_auth')
        click_button I18n.t('requests.form.fields.submit')
        expect(page).to have_button 'Logon to Aeon'
      end
    end
  end
end
