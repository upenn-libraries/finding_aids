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

  context 'with records in the index' do
    let(:solr) { SolrService.new }
    let(:document_hash) { attributes_for(:solr_document, :with_collection_data) }
    let(:document_title) { document_hash[:title_tsi] }
    let(:documents) { [document_hash] }

    before do
      solr.add_many documents: documents
      solr.commit
    end

    after do
      solr.delete_by_endpoint 'test-endpoint'
      solr.commit
    end

    context 'when viewing results' do
      before { visit search_catalog_path search_field: 'all_fields', q: '' }

      it 'shows a result' do
        expect(page).to have_css 'article.document-position-1'
      end

      it 'shows the title with the date' do
        within('article.document-position-1 div.document-main-section header.documentHeader h3') do
          expect(page).to have_link "#{document_title}, 1800", href: solr_document_path(document_hash[:id])
        end
      end

      it 'shows the repository info' do
        within('article.document-position-1 div.document-main-section p.repository-info') do
          expect(page).to have_content "Held at: #{document_hash[:repositoryssi]}"
        end
      end

      it 'shows the contact link' do
        within('article.document-position-1 div.document-main-section p.repository-info') do
          expect(page).to have_link('Contact Us', href: /#{document_hash[:contact_emails_ssm].first}/)
        end
      end

      it 'shows the extent' do
        within('article.document-position-1 div.document-main-section dl.document-metadata') do
          expect(page).to have_content document_hash[:extent_ssim].first
        end
      end

      it 'shows the abstract scope and contents' do
        within('article.document-position-1 div.document-main-section dl.document-metadata') do
          expect(page).to have_content document_hash[:abstract_scope_contents_tsi]
        end
      end
    end

    context 'when searching by an identifier' do
      before { visit search_catalog_path search_field: 'all_fields', q: document_hash[:unit_id_tsi] }

      it 'returns a record when searching by identifier' do
        expect(page).to have_css 'article.document-position-1 h3', text: /#{document_title}/
      end
    end

    context 'when searching by a title' do
      before { visit search_catalog_path search_field: 'all_fields', q: document_title }

      it 'returns a record when searching by title' do
        expect(page).to have_css 'article.document-position-1 h3', text: /#{document_title}/
      end
    end

    context 'when searching by collection information' do
      before { visit search_catalog_path search_field: 'all_fields', q: 'Something Really Distinctive' }

      it 'returns a record when searching by collection information' do
        expect(page).to have_css 'article.document-position-1 h3', text: /#{document_title}/
      end
    end

    context 'with dates spanning centuries' do
      let(:documents) do
        [attributes_for(:solr_document, years_iim: 1701..1800),
         attributes_for(:solr_document, years_iim: 1765..1848)]
      end

      before { visit search_catalog_path search_field: 'all_fields', q: '' }

      it 'displays the expected century facets' do
        within('div.blacklight-era_facet') do
          click_on I18n.t('facets.era.label')
          expect(page).to have_text("#{I18n.t('facets.era.century.eighteenth')} 2")
          expect(page).to have_text("#{I18n.t('facets.era.century.nineteenth')} 1")
        end
      end
    end
  end
end
