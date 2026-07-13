# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::Inventory::Entry do
  include EadHelpers

  describe '.nodes' do
    it 'returns only immediate child component nodes' do
      entry = entry_for(<<~XML)
        <c01>
          <c02 id="one" />
          <c02 id="two">
            <c03 id="three" />
          </c02>
        </c01>
      XML

      nodes = described_class.nodes(entry.node)

      expect(nodes.map { |n| n['id'] }).to eq %w[one two]
    end

    it 'returns an empty NodeSet when there are no child components' do
      entry = entry_for('<c01><did /></c01>')
      expect(described_class.nodes(entry.node)).to be_empty
    end
  end

  describe '.build_entries' do
    it 'builds an Entry for each immediate child component' do
      entry = entry_for(<<~XML)
        <c01>
          <c02 />
          <c02 />
        </c01>
      XML

      children = described_class.build_entries(entry.node)

      expect(children.size).to eq 2
      expect(children).to all(be_a(described_class))
    end

    it 'returns an empty array when there are no child components' do
      entry = entry_for '<c01><did /></c01>'
      expect(described_class.build_entries(entry.node)).to eq []
    end
  end

  describe '#unitid' do
    it 'extracts the unitid, excluding internal/aspace_uri variants' do
      entry = entry_for(<<~XML)
        <c01 level="series">
          <did>
            <unitid audience="internal">internal-id</unitid>
            <unitid type="aspace_uri">/repositories/2/archival_objects/1</unitid>
            <unitid>JES.0001</unitid>
          </did>
        </c01>
      XML

      expect(entry.unitid).to eq('JES.0001')
    end
  end

  describe '#origination' do
    it 'extracts the origination' do
      entry = entry_for(<<~XML)
        <c01 level="series">
        <did><origination><p>Kislak</p></origination></did>
         </c01>
      XML

      expect(entry.origination).to eq('Kislak')
    end
  end

  describe '#extent' do
    it 'extracts the extent' do
      entry = entry_for(<<~XML)
         <c02>
          <did>
          <physdesc><extent><p>1 Folder.</p></extent></physdesc>
          </did>
        </c02>
      XML
      expect(entry.extent).to eq '1 Folder.'
    end
  end

  describe '#bulk_date' do
    it 'extracts the bulk date' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unitdate type="bulk">1950-1960</unitdate>
          </did>
        </c02>
      XML

      expect(entry.bulk_date).to eq '1950-1960'
    end

    it 'returns nil when no bulk date is present' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unitdate>1948</unitdate>
          </did>
        </c02>
      XML

      expect(entry.bulk_date).to be_nil
    end
  end

  describe '#non_bulk_date' do
    it 'extracts a non-bulk date' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unitdate>1948</unitdate>
            <unitdate type="bulk">1950-1960</unitdate>
          </did>
        </c02>
      XML

      expect(entry.non_bulk_date).to eq '1948'
    end

    it 'returns nil when only a bulk date is present' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unitdate type="bulk">1950-1960</unitdate>
          </did>
        </c02>
      XML

      expect(entry.non_bulk_date).to be_nil
    end
  end

  describe '#title_text' do
    it 'extracts the title text' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unittitle>Series I: Correspondence</unittitle>
          </did>
        </c02>
      XML

      expect(entry.title_text).to eq 'Series I: Correspondence'
    end
  end

  describe '#title_html' do
    it 'translates the title to HTML' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unittitle><emph render="italic">Series I</emph></unittitle>
          </did>
        </c02>
      XML

      expect(entry.title_html).to eq '<em>Series I</em>'.html_safe
    end
  end

  describe '#descriptive_metadata' do
    it 'returns descriptive metadata translated into html' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>x</unittitle></did>
          <scopecontent><head>Scope and Contents</head><p>Some text.</p></scopecontent>
        </c02>
      XML

      expect(entry.descriptive_metadata).to eq ["<div><strong>Scope and Contents</strong></div>\n<p>Some text.</p>"]
    end
  end

  describe '#descriptive_metadata_definitions' do
    it 'splits each section into a term (from head) and translated definition' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>x</unittitle></did>
          <scopecontent><head>Scope and Contents</head><p>Some description.</p></scopecontent>
        </c02>
      XML

      definitions = entry.descriptive_metadata_definitions

      expect(definitions.first[:term]).to eq('Scope and Contents')
      expect(definitions.first[:definition]).to include('Some description.')
    end

    it 'excludes a section whose body is blank once the head is removed' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>x</unittitle></did>
          <scopecontent><head>Scope and Contents</head></scopecontent>
        </c02>
      XML

      expect(entry.descriptive_metadata_definitions).to be_empty
    end
  end

  describe '#identification_metadata_definitions' do
    it 'splits each section into a term and translated definition' do
      entry = entry_for(<<~XML)
         <c02>
          <did>
          <unittitle>Correspondence</unittitle>#{' '}
          <physdesc label="Extent"><p>1 Folder.</p></physdesc>
          </did>
        </c02>
      XML

      definitions = entry.identification_metadata_definitions

      expect(definitions.first[:term]).to eq('Extent')
      expect(definitions.first[:definition]).to include('1 Folder.')
    end

    it 'uses a fallback term when there is no label' do
      entry = entry_for(<<~XML)
         <c02>
          <did>
          <unittitle>Correspondence</unittitle>
          <physdesc><p>1 Folder.</p></physdesc>
          </did>
        </c02>
      XML

      definitions = entry.identification_metadata_definitions

      expect(definitions.first[:term]).to eq(I18n.t('inventory.sections.physdesc'))
    end
  end

  describe '#containers' do
    it 'builds a Container for each did/container element' do
      entry = entry_for(<<~XML)
        <c02 level="subseries">
          <did>
            <unittitle></unittitle>
            <container type="Box" label="Correspondence, 1960s">JES.0001</container>
            <container type="Box" label="Correspondence, 1970s">JES.0002</container>
          </did>
        </c02>
      XML

      expect(entry.containers.first).to have_attributes(type: 'Box', label: 'Correspondence, 1960s', text: 'JES.0001')
      expect(entry.containers.last).to have_attributes(type: 'Box', label: 'Correspondence, 1970s', text: 'JES.0002')
    end
  end

  describe '#digital_archival_objects' do
    it 'includes daos with a web url' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unittitle>Scanned letter</unittitle>
            <dao href="https://example.com/scan01.pdf" title="Scan01"/>
            <dao href="https://example.com/scan02.pdf" title="Scan02"/>
          </did>
        </c02>
      XML

      expect(entry.digital_archival_objects.first).to have_attributes(href: 'https://example.com/scan01.pdf',
                                                                      title: 'Scan01')
      expect(entry.digital_archival_objects.last).to have_attributes(href: 'https://example.com/scan02.pdf',
                                                                     title: 'Scan02')
    end

    it 'excludes daos without http hrefs' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unittitle>No href here</unittitle>
            <dao title="Missing href"/>
            <dao href="ftp://example.com/scan01.pdf" title="Scan01"/>
          </did>
        </c02>
      XML

      expect(entry.digital_archival_objects).to be_empty
    end
  end

  describe '#children' do
    it 'wraps each direct child c element as an Entry' do
      entry = entry_for(<<~XML)
        <c01 level="series">
          <did><unittitle>Jesuits</unittitle></did>
          <c02 level="subseries"><did><unittitle></unittitle></did></c02>
          <c02 level="subseries"><did><unittitle></unittitle></did></c02>
        </c01>
      XML

      expect(entry.children.size).to eq(2)
      expect(entry.children).to all(be_a(described_class))
    end
  end

  describe '#children?' do
    it 'is true when there are c children' do
      entry = entry_for(<<~XML)
        <c level="series">
          <did><unittitle>Correspondence</unittitle></did>
          <c><did><unittitle></unittitle></did></c>
        </c>
      XML

      expect(entry.children?).to be true
    end

    it 'is true when there are direct numbered c children' do
      entry = entry_for(<<~XML)
        <c01 level="series">
          <did><unittitle>Correspondence</unittitle></did>
          <c02><did><unittitle></unittitle></did></c02>
        </c01>
      XML

      expect(entry.children?).to be true
    end

    it 'is false when there are no direct c children' do
      entry = entry_for('<c02><did><unittitle>Correspondence</unittitle></did></c02>')

      expect(entry.children?).to be false
    end

    it 'only queries the node once across repeated calls' do
      entry = entry_for(<<~XML)
        <c01 level="series">
          <did><unittitle>Correspondence</unittitle></did>
          <c02><did><unittitle></unittitle></did></c02>
        </c01>
      XML

      expect(entry.node).to receive(:at_xpath).once.and_call_original

      3.times { entry.children? }
    end

    it 'does not requery when the full children array was already built first' do
      entry = entry_for(<<~XML)
        <c01 level="series">
          <did><unittitle>Correspondence</unittitle></did>
          <c02><did><unittitle></unittitle></did></c02>
        </c01>
      XML

      entry.children

      expect(entry.node).not_to receive(:at_xpath)

      expect(entry.children?).to be true
    end
  end

  describe '#additional_contents?' do
    it 'is true when descriptive metadata is present' do
      entry = entry_for(<<~XML)
        <c02>
          <did><unittitle>Has a scope note</unittitle></did>
          <scopecontent><p>Some description.</p></scopecontent>
        </c02>
      XML

      expect(entry.additional_contents?).to be true
    end

    it 'is true when identification metadata is present' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
          <unittitle>Correspondence</unittitle>#{' '}
          <physdesc><p>1 Folder.</p></physdesc>
          </did>
        </c02>
      XML

      expect(entry.additional_contents?).to be true
    end

    it 'is true when dao metadata is present' do
      entry = entry_for(<<~XML)
        <c02>
          <did>
            <unittitle>Scanned letter</unittitle>
            <dao href="https://example.com/scan01.pdf" title="Scan01"/>
          </did>
        </c02>
      XML
      expect(entry.additional_contents?).to be true
    end

    it 'is false when there is nothing beyond the basic did fields' do
      entry = entry_for('<c02><did><unittitle>Plain entry</unittitle></did></c02>')

      expect(entry.additional_contents?).to be false
    end
  end
end
