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

  it 'shows the title' do
    within('div#document div.document-main-section header.documentHeader h1.document-title-heading') do
      expect(page).to have_content document_hash[:title_tsi]
    end
  end

  it 'shows the repository info' do
    within('div#document div.document-main-section div#overview p.repository-info') do
      expect(page).to have_content "Held at: #{document_hash[:repositoryssi]}"
    end
  end

  it 'shows repository address' do
    within('div#document div.document-main-section div#overview p.repository-info span.repository-location') do
      expect(page).to have_content document_hash[:repository_address_ssi]
    end
  end

  it 'shows contact link' do
    within('div#document div.document-main-section div#overview p.repository-info') do
      expect(page).to have_link 'Contact Us', href: /#{document_hash[:contact_emails_ssm].first}/
    end
  end

  it 'shows the access clarification message' do
    within('div#document div.document-main-section div#overview p.access-clarification') do
      expect(page).to have_content(/This is a finding aid. It is a description of archival material/)
    end
  end

  it 'shows the suggestion email' do
    within('div#document div.document-main-section ul.show-page-links li.suggest') do
      expect(page).to have_link 'Suggest a correction', href: /#{document_hash[:contact_emails_ssm].first}/
    end
  end

  it 'expands the collection overview' do
    within('div#document div.document-main-section div#overview') do
      expect(page).to have_css('div#collection-overview.show')
    end
  end

  it 'shows the expected metadata in the collections overview' do
    within('div#document div.document-main-section div#overview div#collection-overview dl.document-metadata') do
      expect(page).to have_content document_hash[:pretty_unit_id_ss]
      expect(page).to have_content document_hash[:creators_ssim].first
    end
  end

  it 'expands the biography history overview' do
    within('div#document div.document-main-section div#overview') do
      expect(page).to have_css('div#biography-history.show')
    end
  end

  it 'shows the expected metadata in the biography-history overview' do
    within('div#document div.document-main-section div#overview div#biography-history') do
      expect(page).to have_content 'This committee was established in...'
    end
  end

  it 'expands the scope and contents overview' do
    within('div#document div.document-main-section div#overview') do
      expect(page).to have_css('div#scope-and-content.show')
    end
  end

  it 'shows the expected metadata in the scope and contents overview' do
    within('div#document div.document-main-section div#overview div#scope-and-content') do
      expect(page).to have_content 'This collection contains...'
    end
  end

  it 'expands the collection inventory' do
    within('div#document div.document-main-section div#inventory') do
      expect(page).to have_css('div#collection-1.show')
    end
  end

  it 'expands the expected collection inventory' do
    within('div#document div.document-main-section div#inventory div#collection-1') do
      expect(page).to have_content 'Something Really Distinctive. Box 1 Another Really Distinctive Thing. Box 2'
    end
  end

  context 'without language note' do
    it 'does not display language note field' do
      expect(page).to have_text(I18n.t('fields.language_note'), count: 0)
    end
  end

  context 'with language note' do
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

    it 'displays the language note field' do
      expect(page).to have_text(I18n.t('fields.language_note'))
      expect(page).to have_text 'Mostly in English, but some materials contain Esperanto.'
    end
  end

  context 'when language note is the same as languages field' do
    let(:xml_ss) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <ead xsi:schemaLocation="urn:isbn:1-931666-22-9 http://www.loc.gov/ead/ead.xsd">
          <archdesc level="collection">
            <did>
              <langmaterial>
               <language langcode="eng">English</language>
               <language langcode="fre">French</language>
              </langmaterial>
            </did>
            <dsc><c id="ref1" level="series"></c></dsc>
          </archdesc>
        </ead>
      XML
    end
    let(:document_hash) { attributes_for(:solr_document, languages_ssim: %w[English French], xml_ss: xml_ss) }

    it 'does not display language note field' do
      expect(page).to have_text(I18n.t('fields.language_note'), count: 0)
    end
  end
end
