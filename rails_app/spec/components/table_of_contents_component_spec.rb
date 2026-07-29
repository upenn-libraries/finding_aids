# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TableOfContentsComponent, type: :component do
  include EadHelpers

  let(:document) { SolrDocument.new(attributes_for(:solr_document, :with_collection_data)) }
  let(:presenter) { Catalog::ShowDocumentPresenter.new(document, view_context, CatalogController.new.blacklight_config) }

  let(:view_context) { vc_test_controller.view_context }

  describe 'rendering' do
    context 'with inventory' do
      it 'renders a link for each top-level entry' do
        entries = [
          entry_for('<c01 level="series"><did><unittitle>Series One</unittitle></did></c01>'),
          entry_for('<c01 level="series"><did><unittitle>Series Two</unittitle></did></c01>')
        ]

        render_inline(described_class.new(document: document, presenter: presenter, entries: entries))

        expect(page).to have_link('Series One', href: '#series-1')
        expect(page).to have_link('Series Two', href: '#series-2')
      end

      it 'nests a child link only when that child itself has children' do
        entries = [
          entry_for(<<~XML, xpath: '//c01')
            <c01 level="series">
              <did><unittitle>Series </unittitle></did>
              <c02><did><unittitle>Child subseries</unittitle></did></c02>
              <c02><did><unittitle>Nested child subseries</unittitle></did>
                <c03><did><unittitle>File</unittitle></did></c03>
              </c02>
            </c01>
          XML
        ]

        render_inline(described_class.new(document: document, presenter: presenter, entries: entries))

        expect(page).to have_no_css('a', text: 'Child subseries')
        expect(page).to have_css('a', text: 'Nested child subseries')
      end

      it 'assigns child ids based on sibling position' do
        entries = [
          entry_for(<<~XML, xpath: '//c01')
            <c01 level="series">
              <did><unittitle>Series</unittitle></did>
              <c02><did><unittitle>Leaf A</unittitle></did></c02>
              <c02>
                <did><unittitle>Branch B</unittitle></did>
                <c03><did><unittitle>File</unittitle></did></c03>
              </c02>
              <c02><did><unittitle>Leaf C</unittitle></did></c02>
              <c02>
                <did><unittitle>Branch D</unittitle></did>
                <c03><did><unittitle>File</unittitle></did></c03>
              </c02>
            </c01>
          XML
        ]

        render_inline(described_class.new(document: document, presenter: presenter, entries: entries))

        expect(page).to have_css('Branch B', href: '#series-1-2')
        expect(page).to have_css('Branch D', href: '#series-1-4')
      end

      it 'obeys the depth provided' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Level 1</unittitle></did>
            <c02>
              <did><unittitle>Level 2</unittitle></did>
            </c02>
          </c01>
        XML

        render_inline(described_class.new(document: document, presenter: presenter, entries: [entry], depth: 1))

        expect(page).to have_css('a', text: 'Level 1')
        expect(page).to have_no_css('a', text: 'Level 2')
      end

      it 'does not recurse past MAX_DEPTH' do
        deeply_nested = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Level 1</unittitle></did>
            <c02>
              <did><unittitle>Level 2</unittitle></did>
              <c03>
                <did><unittitle>Level 3</unittitle></did>
                <c04>
                  <did><unittitle>Level 4</unittitle></did>
                  <c05><did><unittitle>Level 5</unittitle></did></c05>
                </c04>
              </c03>
            </c02>
          </c01>
        XML

        render_inline(described_class.new(document: document, presenter: presenter, entries: [deeply_nested]))

        expect(page).to have_css('a', text: 'Level 3')
        expect(page).to have_no_css('a', text: 'Level 4')
      end
    end
  end
end
