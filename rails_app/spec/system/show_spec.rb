# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Catalog Show' do
  include EadHelpers
  include Turbo::SystemTestHelper

  let(:document) { attributes_for(:solr_document, xml_ss: xml) }
  let(:xml) do
    <<~XML
      <ead>
        <archdesc level="collection">
            <did></did>
            <scopecontent>This collection contains...</scopecontent>
            <bioghist>This committee was established in...</bioghist>
            <dsc>
              <c level="series"><did><unittitle>Series One</unittitle></did>
                <c level="file"><did><unittitle>Series One--subseries</unittitle></did>
                  <c level="file"><did><unittitle>Some file</unittitle></did>
                  </c>
                </c>
              </c>
              <c level="series"><did><unittitle>Series Two</unittitle></did></c>
            </dsc>
        </archdesc>
      </ead>
    XML
  end

  before { seed_solr([document]) }
  after  { cleanup_solr([document]) }

  describe 'guide navigation' do
    it 'expands top level inventory upon initial load when nested inventory is not in the dom' do
      entry = entry_for('<c level="series"><did><unittitle>Series One</unittitle></did></c>')
      allow(Ead::Extraction::Inventory::Entry).to receive(:build_entries).and_return([entry])
      visit solr_document_path(document[:id], anchor: 'series-1-1')

      expect(page).to have_css('details[open] summary h3#series-1')
      expect(page).to have_no_css('details[open] summary h4#series-1-1', visible: :all)
    end

    it 'expands nested inventory containing URL location after turbo frame loads' do
      visit solr_document_path(document[:id], anchor: 'series-1-1')

      expect(page).to have_css('details[open] summary h3#series-1')
      expect(page).to have_css('details[open] summary h4#series-1-1')
    end

    it 'expands nested inventory when clicking table of contents link' do
      visit solr_document_path(document[:id])
      click_link 'Series One--subseries'

      expect(page).to have_css('details[open] summary h3#series-1')
      expect(page).to have_css('details[open] summary h4#series-1-1', visible: :all)
    end
  end
end
