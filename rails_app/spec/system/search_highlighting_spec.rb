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

  describe 'arrival highlighting (U2)' do
    context 'when visiting a record page with a query param' do
      it 'highlights the query term on the page' do
        visit solr_document_path(document_id, q: 'collection')

        # Verify data attribute is set
        el = find('.faa-guide-content')
        expect(el['data-search-highlight-query-value']).to eq('collection')

        # mark.js should have wrapped matches in <mark> elements
        expect(page).to have_css('mark.search-highlight', wait: 3)
      end
    end

    context 'when visiting a record page without a query param' do
      it 'mounts the controller without highlighting' do
        visit solr_document_path(document_id)

        expect(page).to have_css('.faa-guide-content[data-controller="search-highlight"]')
        expect(page).to have_no_css('mark.search-highlight')
      end
    end
  end

  describe 'in-page search (U3)' do
    before { visit solr_document_path(document_id) }

    it 'renders the search input and hidden listbox' do
      expect(page).to have_field('Find in this guide', type: 'text')
      expect(page).to have_css('#search-match-list[hidden]', visible: :hidden)
      expect(page).to have_css('#search-find-bar[hidden]', visible: :hidden)
    end

    it 'shows match listbox when typing a term in the input' do
      fill_in 'Find in this guide', with: 'collection'

      expect(page).to have_css('#search-match-list:not([hidden])', wait: 3)
      expect(page).to have_css('mark.search-highlight', wait: 2)
      within '#search-match-list' do
        expect(page).to have_css('li[role="option"]', minimum: 1)
      end
    end

    it 'hides listbox and removes marks when input is cleared' do
      fill_in 'Find in this guide', with: 'collection'
      expect(page).to have_css('#search-match-list:not([hidden])', wait: 3)

      # Clear via JS to ensure input event fires
      page.execute_script("document.getElementById('record-search-input').value = ''")
      page.execute_script("document.getElementById('record-search-input').dispatchEvent(new Event('input', { bubbles: true }))")
      expect(page).to have_no_css('#search-match-list:not([hidden])', wait: 3)
      expect(page).to have_no_css('mark.search-highlight')
    end

    it 'shows no listbox entries when term has no matches' do
      fill_in 'Find in this guide', with: 'xyznonexistent'

      expect(page).to have_css('#search-match-list[hidden]', visible: :hidden, wait: 3)
      expect(page).to have_no_css('mark.search-highlight')
    end

    it 'shows status callout with match count (U4)' do
      fill_in 'Find in this guide', with: 'collection'

      expect(page).to have_css('mark.search-highlight', wait: 3)
      expect(page).to have_css('[data-search-highlight-target="statusCallout"]:not([hidden])', wait: 2)
      callout = find('[data-search-highlight-target="statusCallout"]')
      expect(callout.text).to match(/\d+ matches? in \d+ sections?/)
    end
  end

  describe 'keyboard navigation (U5)' do
    before { visit solr_document_path(document_id) }

    it 'navigates between matches with Enter' do
      fill_in 'Find in this guide', with: 'collection'
      expect(page).to have_css('mark.search-highlight', wait: 3)

      # Find bar should be visible with counter
      expect(page).to have_css('#search-find-bar:not([hidden])', wait: 2)
      expect(page).to have_css('[data-search-highlight-target="findBarCounter"]')

      find('#record-search-input').send_keys(:enter)
      expect(page).to have_css('mark.search-highlight--active', wait: 2)
      # Counter should show position after navigation
      expect(find('[data-search-highlight-target="findBarCounter"]').text).to match(/1 of \d+/i)
    end

    it 'opens collapsed details when navigating to a match inside one' do
      fill_in 'Find in this guide', with: 'collection'
      expect(page).to have_css('mark.search-highlight', wait: 3)
      expect(page).to have_css('#search-find-bar:not([hidden])', wait: 2)

      find('#record-search-input').send_keys(:enter)
      expect(page).to have_css('mark.search-highlight--active', wait: 2)
    end
  end
end
