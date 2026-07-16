# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryComponent, type: :component do
  include EadHelpers
  describe 'rendering' do
    it 'renders a details component with the expected title' do
      entry = entry_for(<<~XML, xpath: '//c01')
        <c01 level="series">
          <did><unittitle>Series</unittitle>
            <physdesc><extent>2.0 Linear Feet</extent></physdesc>
            <origination>Kislak</origination>
            <unitdate>1900</unitdate>
            </did>
            </c01>
      XML

      render_inline(described_class.new(entry: entry, index: 1))

      expect(page).to have_css('details.fa-guide__details', text: 'Kislak. Series, 1900 2 Linear Feet.')
    end

    context 'when an entry has children' do
      let(:entry) do
        entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did>
              <unittitle>Series</unittitle><physloc>Some Archives</physloc>
              <dao href="https://example.com/scan01.pdf" title="Scan01"/>
            </did>
            <bioghist><head>Biographical History</head><p>Some Biography</p></bioghist>
            <c02>
              <did>
              <unittitle>Subseries A</unittitle>
              </did>
              <c03><did><unittitle>File</unittitle></did></c03>
            </c02>
            </c01>
        XML
      end

      before { render_inline(described_class.new(entry: entry, index: 1)) }

      it "renders the entry's translated descriptive metadata" do
        expect(page).to have_css('details div.pl-flex.pl-flex-col.pl-gap-s div strong', text: 'Biographical History',
                                                                                        visible: :all)
        expect(page).to have_css('details div.pl-flex.pl-flex-col.pl-gap-s p', text: 'Some Biography',
                                                                               visible: :all)
      end

      it "renders the entry's identification metadata in a description list" do
        expect(page).to have_css('details div.pl-flex.pl-flex-col.pl-gap-s dl.pl-dl--inline dt',
                                 text: 'Physical Location', visible: :all)
        expect(page).to have_css('details div.pl-flex.pl-flex-col.pl-gap-s dl.pl-dl--inline dd',
                                 text: 'Some Archives', visible: :all)
      end

      it "renders the entry's digital archival object links in a description list" do
        expect(page).to have_css('details div.pl-flex.pl-flex-col.pl-gap-s dl.pl-dl--inline dt',
                                 text: 'View Online', visible: :all)
        expect(page).to have_css(
          'details div.pl-flex.pl-flex-col.pl-gap-s dl.pl-dl--inline dd a[@href="https://example.com/scan01.pdf"]',
          text: 'Scan01', visible: :all
        )
      end
    end

    context "when and entry's children all have children" do
      let(:entry) do
        entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02>
              <did>
              <unittitle>Subseries A</unittitle>
              </did>
              <c03><did><unittitle>File</unittitle></did></c03>
            </c02>
             <c02>
              <did><unittitle>Subseries B</unittitle></did>
              <c03><did><unittitle>File</unittitle></did></c03>
            </c02>
          </c01>
        XML
      end

      let(:outer_entry_details) { page.first('details.fa-guide__details') }

      before { render_inline(described_class.new(entry: entry, index: 1)) }

      it 'does not render a table' do
        expect(outer_entry_details).not_to have_css('> div > table.table--responsive-small', visible: :all)
      end

      it 'renders child entries as nested details' do
        expect(outer_entry_details).to have_css('details.fa-guide__details--subseries', text: 'Subseries A',
                                                                                        visible: :all)
        expect(outer_entry_details).to have_css('details.fa-guide__details--subseries', text: 'Subseries B',
                                                                                        visible: :all)
      end
    end

    context "when an entry's children are all childless" do
      let(:entry) do
        entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02>
              <did><unittitle>Subseries A</unittitle><unitdate>1909</unitdate>
              <container type="Box" >1</container>
              <container type="Folder" >1</container>
              </did>
            </c02>
            <c02>
              <did><unittitle>Subseries B</unittitle><unitdate type="bulk">1910-1919</unitdate>
              <container type="Box" >2</container>
              <container type="Folder" >1-10</container>
              </did>
            </c02>
          </c01>
        XML
      end

      let(:outer_entry_details) { page.first('details.fa-guide__details') }

      before { render_inline(described_class.new(entry: entry, index: 1)) }

      it 'renders a table' do
        expect(outer_entry_details).to have_css('table.table--responsive-small', visible: :all)
      end

      it 'renders the Contents, Dates, and Containers table headers' do
        css_path = '> div > table.table--responsive-small > thead > tr > th'

        expect(outer_entry_details).to have_css(css_path, count: 3, visible: :all)
        %w[Contents Dates Container].each do |header|
          expect(outer_entry_details).to have_css(css_path, count: 1, text: header, visible: :all)
        end
      end

      it 'renders a row for each entry' do
        expect(outer_entry_details).to have_css(' > div > table.table--responsive-small > tr.inventory-row',
                                                count: 2, visible: :all)
      end

      it 'includes metadata in table row data attributes' do
        css = 'tr.inventory-row[data-title="Subseries A"][data-dates=1909][data-container="Box 1, Folder 1"]'
        expect(outer_entry_details).to have_css(css, visible: :all)
      end

      it 'renders the Contents' do
        css = ' > div > table.table--responsive-small > tr.inventory-row > td[data-th="Contents"]'
        expect(outer_entry_details).to have_css(css, text: 'Subseries A', count: 1, visible: :all)
        expect(outer_entry_details).to have_css(css, text: 'Subseries B', count: 1, visible: :all)
      end

      it 'renders the Dates' do
        css = '> div > table.table--responsive-small > tr.inventory-row > td[data-th="Dates"]'
        expect(outer_entry_details).to have_css(css, text: '1909', count: 1, visible: :all)
        expect(outer_entry_details).to have_css(css, text: '1910-1919', count: 1, visible: :all)
      end

      it 'renders the Containers' do
        css = ' > div > table.table--responsive-small > tr.inventory-row > td[data-th="Container"]'
        expect(outer_entry_details).to have_css(css, text: 'Box 1, Folder 1', count: 1, visible: :all)
        expect(outer_entry_details).to have_css(css, text: 'Box 2, Folder 1-10', count: 1, visible: :all)
      end
    end

    context "when an entry's children have mixed nesting" do
      let(:entry) do
        entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02>
              <did><unittitle>Subseries A</unittitle><unitdate>2000</unitdate>
              <container type="Box" >1</container>
              <container type="Folder" >1</container>
              </did>
            </c02>
             <c02>
              <did><unittitle>Subseries B</unittitle></did>
              <c03>
              <did><unittitle>Journals</unittitle>
              <container type="Box" >1</container>
              </did>
              </c03>
            </c02>
          </c01>
        XML
      end

      before { render_inline(described_class.new(entry: entry, index: 1)) }

      it 'renders a nested inventory detail as a table row' do
        outer_entry_details = page.first('details.fa-guide__details')

        expect(outer_entry_details).to have_css(
          '> div > table > tr td[colspan="3"] details.fa-guide__details--subseries',
          text: 'Subseries B', visible: :all
        )
      end

      it 'maintains the order of the series' do
        expect(page).to have_css('details.fa-guide__details--subseries summary > h4#series-1-2',
                                 text: 'Subseries B', visible: :all)
      end
    end

    context 'when an entry has no children' do
      it 'renders the entry within a table' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Subseries A</unittitle><unitdate>2000</unitdate>
             <container type="Box" >1</container>
             <container type="Folder" >1</container>
            </did>
          </c01>
        XML
        render_inline(described_class.new(entry: entry, index: 1))

        outer_entry_details = page.first('details.fa-guide__details')

        expect(outer_entry_details).to have_css('> div > table > tr', text: 'Subseries A', visible: :all)
        expect(page).to have_css('tr.inventory-row', count: 1, visible: :all)
      end
    end

    context 'when an entry is requestable' do
      it 'renders the select column' do
        entry = entry_for('<c01 level="series"><did><unittitle>Files</unittitle></did></c01>', xpath: '//c01')

        render_inline(described_class.new(entry: entry, index: 1, requestable: true))

        expect(page).to have_css('th', text: 'Select', visible: :all)
        expect(page).to have_css('input.fa-visit__checkbox', visible: :all)
      end

      it 'renders a nested details that spans 4 columns' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02><did><unittitle>Leaf</unittitle></did></c02>
            <c02>
              <did><unittitle>Branch subseries</unittitle></did>
              <c03><did><unittitle>File</unittitle></did></c03>
            </c02>
          </c01>
        XML
        render_inline(described_class.new(entry: entry, index: 1, requestable: true))

        expect(page).to have_css('td[colspan="4"]', visible: :all)
        expect(page).to have_no_css('td[colspan="3"]')
      end

      it 'forwards requestable to its children' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02>
              <did><unittitle>Subseries</unittitle></did>
              <c03><did><unittitle></unittitle><container type="Box">1</container></did></c03>
            </c02>
          </c01>
        XML

        render_inline(described_class.new(entry: entry, index: 1, requestable: true))
        expect(page).to have_css('details.fa-guide__details--subseries th', text: 'Select', visible: :all)
        expect(page).to have_css('details.fa-guide__details--subseries input.fa-visit__checkbox', visible: :all)
      end
    end

    context 'when an entry is not requestable' do
      it 'does not render the select column' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Jesuits</unittitle></did>
            <c02><did><unittitle></unittitle><container type="Box">JES.0001</container></did></c02>
          </c01>
        XML
        render_inline(described_class.new(entry: entry, index: 1, requestable: false))

        expect(page).to have_no_css('th', text: 'Select')
        expect(page).to have_no_css('input.fa-visit__checkbox')
      end

      it 'renders a nested details that span 3 columns' do
        entry = entry_for(<<~XML, xpath: '//c01')
          <c01 level="series">
            <did><unittitle>Series</unittitle></did>
            <c02><did><unittitle>Leaf</unittitle></did></c02>
            <c02>
              <did><unittitle>Branch subseries</unittitle></did>
              <c03><did><unittitle>File</unittitle></did></c03>
            </c02>
          </c01>
        XML

        render_inline(described_class.new(entry: entry, index: 1, requestable: false))

        expect(page).to have_css('td[colspan="3"]', visible: :all)
        expect(page).to have_no_css('td[colspan="4"]')
      end
    end
  end

  context 'when an entry rendered in the table has additional metadata' do
    it 'renders the title within a description list' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>Minutes</unittitle><origination>Some Organization</origination></did>
          <scopecontent><head>Scope and Contents</head><p>Correspondence, 1960s.</p></scopecontent>
        </c02>
      XML

      render_inline(described_class.new(entry: entry, index: 1))
      contents = page.first('td[data-th="Contents"] dl.pl-dl--inline', visible: :all)
      expect(contents).to have_css('dt', text: 'Title', visible: :all)
      expect(contents).to have_css('dd', text: 'Some Organization. Minutes', visible: :all)
    end

    it 'renders the descriptive metadata within a description list' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>Series</unittitle></did>
          <scopecontent><head>Scope and Contents</head><p>Correspondence, 1960s.</p></scopecontent>
        </c02>
      XML

      render_inline(described_class.new(entry: entry, index: 1))
      contents = page.first('td[data-th="Contents"] dl.pl-dl--inline', visible: :all)

      expect(contents).to have_css('dt', text: 'Scope and Contents', visible: :all)
      expect(contents).to have_css('dd', text: 'Correspondence, 1960s.', visible: :all)
    end

    it 'renders identification metadata within a description list' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>Series</unittitle><physdesc label="Extent Note">3 folders</physdesc></did>
        </c02>
      XML

      render_inline(described_class.new(entry: entry, index: 1))
      contents = page.first('td[data-th="Contents"] dl.pl-dl--inline', visible: :all)

      expect(contents).to have_css('dt', text: 'Extent Note', visible: :all)
      expect(contents).to have_css('dd', text: '3 folders', visible: :all)
    end

    it "renders the entry's digital archival object links in a description list" do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>Series</unittitle><dao href="https://example.com/scan01.pdf" title="Scan01"/></did>
        </c02>
      XML

      render_inline(described_class.new(entry: entry, index: 1))
      contents = page.first('td[data-th="Contents"] dl.pl-dl--inline', visible: :all)

      expect(contents).to have_css('dt', text: 'View Online', visible: :all)
      expect(contents).to have_css('dd a[@href="https://example.com/scan01.pdf"]', text: 'Scan01', visible: :all)
    end
  end
end
