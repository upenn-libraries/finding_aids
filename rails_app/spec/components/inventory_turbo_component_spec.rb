# frozen_string_literal: true

RSpec.describe InventoryTurboComponent, type: :component do
  include EadHelpers

  let(:document) { SolrDocument.new(attributes_for(:solr_document)) }
  let(:presenter) do
    Catalog::ShowDocumentPresenter.new(document, vc_test_controller.view_context,
                                       CatalogController.new.blacklight_config)
  end
  let(:entries) do
    [
      entry_for(<<~XML
        <c level="series">
         <did><unittitle>Series One</unittitle></did>
         <c level="file"><did><unittitle>Series One--subseries</unittitle></did>
           <c level="file"><did><unittitle>Some file</unittitle></did></c>
         </c>
        </c>
      XML
               ),
      entry_for('<c01 level="series"><did><unittitle>Series Two</unittitle></did></c01>')
    ]
  end

  before { render_inline described_class.new(entries: entries, document: document, presenter: presenter) }

  describe 'rendering' do
    it 'renders incoming turbo frame' do
      expect(page).to have_css('turbo-frame#inventory-frame')
    end

    it 'renders a turbo stream to replace initial table of contents' do
      expect(page).to have_css('turbo-stream[action="replace"][target="toc-list"] template', visible: :all)
    end

    it 'renders nested table of contents inside the turbo stream' do
      doc = Nokogiri::HTML5.fragment(render_inline(described_class.new(entries: entries, document: document,
                                                                       presenter: presenter)))
      template = Nokogiri::HTML5.fragment(doc.at_css('turbo-stream template').inner_html)

      expect(template.at_css('ul#toc-list')).to be_present
      expect(template.text).to include(document.title, 'Description', 'Inventory', 'Series One', 'Series Two',
                                       'Series One--subseries')
    end

    it 'renders a nested inventory collection' do
      css = 'turbo-frame#inventory-frame pennlibs-accordion#inventory-accordion'
      expect(page).to have_css("#{css} details summary h4#series-1-1", visible: :all)
      expect(page).to have_css("#{css} details summary h3#series-2")
    end
  end
end
