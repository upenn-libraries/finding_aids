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

  describe 'arrival highlighting' do
    context 'when visiting a record page with a query param' do
      it 'highlights the query term and shows a match-count callout' do
        visit solr_document_path(document_id, q: 'collection')

        expect(page).to have_css('mark.search-highlight', wait: 3)

        # Callout should show match count
        expect(page).to have_css('[data-search-highlight-target="statusCallout"]:not([hidden])', wait: 2)
        expect(find('[data-search-highlight-target="statusText"]').text).to match(/matches? for "collection"/)

        # Expand button should be visible
        expect(page).to have_css('[data-search-highlight-target="expandButton"]:not([hidden])')
      end

      it 'expands matching details sections when the expand button is clicked' do
        visit solr_document_path(document_id, q: 'collection')
        expect(page).to have_css('mark.search-highlight', wait: 3)

        click_button 'Expand matching sections'

        # All <details> containing marks should be open
        marks_inside_closed_details = page.evaluate_script(<<~JS)
          [...document.querySelectorAll('mark.search-highlight')]
            .filter(m => { const d = m.closest('details'); return d && !d.open; }).length
        JS
        expect(marks_inside_closed_details).to eq(0)
      end
    end

    context 'when visiting a record page without a query param' do
      it 'does not highlight or show the callout' do
        visit solr_document_path(document_id)

        expect(page).to have_no_css('mark.search-highlight')
        expect(page).to have_css('[data-search-highlight-target="statusCallout"][hidden]', visible: :hidden)
      end
    end
  end
end
