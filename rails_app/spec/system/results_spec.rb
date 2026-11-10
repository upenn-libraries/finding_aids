# frozen_string_literal: true

require 'system_helper'

describe 'Blacklight search results' do
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

    context 'with dates spanning centuries' do
      let(:documents) do
        [attributes_for(:solr_document, years_iim: 1701..1800),
         attributes_for(:solr_document, years_iim: 1765..1848)]
      end

      before { visit search_catalog_path search_field: 'all_fields', q: '' }

      it 'displays the expected century facets' do
        within('.blacklight-era_facet') do
          find('summary', text: I18n.t('facets.era.label')).click
          expect(page).to have_text("#{I18n.t('facets.era.century.eighteenth')} 2")
          expect(page).to have_text("#{I18n.t('facets.era.century.nineteenth')} 1")
        end
      end
    end
  end
end
