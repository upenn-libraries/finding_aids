# frozen_string_literal: true

require 'system_helper'

describe 'Blacklight show page' do
  let(:solr) { SolrService.new }
  let(:document_hash) { attributes_for(:solr_document, :with_collection_data) }

  before do
    solr.add_many documents: [document_hash]
    solr.commit
    visit solr_document_path(document_hash[:id])
  end

  after do
    solr.delete_by_endpoint 'test-endpoint'
    solr.commit
  end

  context 'without langmaterial text content' do
    it 'does not display language notes dynamic field' do
      expect(page).to have_text(I18n.t('fields.language_note'), count: 0)
    end
  end

  context 'with langmaterial text content' do
    let(:xml_ss) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
          <archdesc level="collection">
            <did>
            <langmaterial>
              Mostly in <language langcode="eng">English</language>, but some materials contain Esperanto.
            </langmaterial>
            </did>
            <dsc><c id="ref1" level="series"></c></dsc>
          </archdesc>
        </ead>
      XML
    end
    let(:document_hash) { attributes_for(:solr_document, xml_ss: xml_ss) }

    it 'displays the language notes dynamic field' do
      expect(page).to have_text(I18n.t('fields.language_note'))
      expect(page).to have_text 'Mostly in English, but some materials contain Esperanto.'
    end
  end
end
