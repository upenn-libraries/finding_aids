# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Inventory', type: :request do
  let(:document) { attributes_for(:solr_document, xml_ss: xml) }
  let(:xml) do
    <<~XML
      <ead>
        <archdesc level="collection">
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

  describe 'GET /inventory/:id/details' do
    before { get details_inventory_path(document[:id]) }

    it 'responds successfully' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the inventory turbo frame' do
      html = Nokogiri::HTML5.fragment(response.body)
      frame = html.at_css('turbo-frame#inventory-frame')
      expect(frame).to be_present
    end

    it 'renders a turbo stream replacing the table of contents' do
      html = Nokogiri::HTML5.fragment(response.body)
      stream = html.at_css('turbo-stream[action="replace"][target="toc-list"]')
      expect(stream).to be_present
    end

    it 'renders the table of contents inside the turbo stream' do
      html = Nokogiri::HTML5.fragment(response.body)

      template = Nokogiri::HTML5.fragment(html.at_css('turbo-stream template').inner_html)

      expect(template.at_css('ul#toc-list')).to be_present
      expect(template.text).to include(document[:title_tsi], 'Description', 'Biography/History', 'Scope and Content',
                                       'Inventory', 'Series One', 'Series Two', 'Series One--subseries')
    end

    it 'renders the inventory accordion inside' do
      expect(response.body).to include('id="inventory-accordion"', 'id="series-1-1"')
    end
  end
end
