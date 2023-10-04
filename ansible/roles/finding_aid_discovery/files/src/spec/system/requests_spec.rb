# frozen_string_literal: true

require 'system_helper'

describe 'Requests form' do
  let(:solr) { SolrService.new }
  let(:document_hash) { attributes_for(:solr_document, :requestable, :with_collection_data) }
  let(:document_title) { document_hash[:title_tsi] }

  # Index a requestable record
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
    let(:collection_form_params) do
      {
        c: { 'Box_1' => { 'Album_2' => '1' } },
        call_num: 'Ms. Coll. 12345',
        repository: AeonRequest::KISLAK_REPOSITORY_NAME,
        title: 'Test Title'
      }
    end

    it 'the page includes a request checkbox' do
      expect(page).to have_field 'c[Box_1]', visible: :hidden
    end

    context 'when confirming the request' do
      before do
        check 'c[Box_1]', visible: false
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

  context 'with collection encoded with supported ead3 tags' do
    let(:document_hash) { attributes_for(:solr_document, :requestable, :with_ead3_collection_data) }

    it 'includes the date in the collection title' do
      expect(page).to have_text('Test Collection, 2000-2010.')
    end

    it 'prefers <daterange> over <singledate>' do
      expect(page).not_to have_text('2005')
    end

    it 'formats bulk dates correctly' do
      within '#collection-1-1-title' do
        expect(page).to have_text('Something Really Distinctive, (2001).')
      end
    end

    it 'appends the structured extent to the title' do
      expect(page).to have_text('Test Collection, 2000-2010. 143 electronic files.')
    end

    it 'only appends the first structured extent to the title' do
      expect(page).not_to have_text('6 compact discs')
    end
  end
end
