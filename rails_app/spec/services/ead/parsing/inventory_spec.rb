# frozen_string_literal: true

RSpec.describe Ead::Parsing::Inventory do
  describe '.nodes' do
    it 'returns the highest level of c elements' do
      xml = <<~XML
         <dsc>
         <c level="series" position="first"><did><unittitle>First</unittitle></did></c>
         <c level="series" position="second"><did><unittitle>Second</unittitle></did></c>
         <c level="series" position="third"><did><unittitle>Third</unittitle></did>
           <c level="sub-series" position="fourth"><did><unittitle>Fourth</unittitle></did></c>
         </c>
         <c level="series" position="fifth"><did><unittitle>Third</unittitle></did></c>
        </dsc>
      XML
      node = Nokogiri::XML(xml).at_xpath('dsc')
      nodes = described_class.nodes(node)
      expect(nodes.size).to eq(4)
      expect(nodes.map { |n| n.attr('position') }).to contain_exactly('first', 'second', 'third', 'fifth')
    end

    it 'returns the top level numbered c elements' do
      xml = <<~XML
         <dsc>
         <c03 level="series" position="first"><did><unittitle>First</unittitle></did></c>
         <c03 level="series" position="second"><did><unittitle>Second</unittitle></did></c>
         <c03 level="series" position="third"><did><unittitle>Third</unittitle></did>
           <c04 level="sub-series" position="fourth"><did><unittitle>Fourth</unittitle></did></c>
         </c>
         <c03 level="series" position="fifth"><did><unittitle>Third</unittitle></did></c>
        </dsc>
      XML

      node = Nokogiri::XML(xml).at_xpath('dsc')
      nodes = described_class.nodes(node)
      expect(nodes.size).to eq(4)
      expect(nodes.map { |n| n.attr('position') }).to contain_exactly('first', 'second', 'third', 'fifth')
    end

    it 'uses the expected xpath' do
      node = Nokogiri::XML('<dsc><c05><did><unittitle>First</unittitle></did></c05></dsc>').at_xpath('dsc')
      xpath = 'c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12'
      allow(node).to receive(:xpath)
      expect(node).to receive(:xpath).with(xpath)
      described_class.nodes(node)
    end
  end

  describe '.head' do
    it 'returns the head element node' do
      node = Nokogiri::XML('<c05><bioghist><head>Some heading</head></bioghist></c05>').at_xpath('c05/bioghist')
      expect(described_class.head(node).name).to eq('head')
    end

    it 'returns nil when the head element is not present' do
      node = Nokogiri::XML('<c05><bioghist></bioghist></c05>').at_xpath('c05/bioghist')
      expect(described_class.head(node)).to be_nil
    end
  end

  describe '#unitid' do
    it 'returns the unitid node' do
      node = Nokogiri::XML('<c><did><unitid>Some id</unitid></did></c05>').at_xpath('c')
      parser = described_class.new(node)
      expect(parser.unitid.name).to eq 'unitid'
    end

    it 'ignores internal ids' do
      node = Nokogiri::XML('<c><did><unitid audience="internal">Some id</unitid></did></c><').at_xpath('c')
      parser = described_class.new(node)
      expect(parser.unitid).to be_nil
    end

    it 'ignores aspace URIs' do
      node = Nokogiri::XML('<c><did><unitid type="aspace_uri">Some id</unitid></did></c><').at_xpath('c')
      parser = described_class.new(node)
      expect(parser.unitid).to be_nil
    end
  end

  describe '#origination' do
    it 'returns the origination node' do
      node = Nokogiri::XML('<c><did><origination>John Doe</origination></did></c>').at_xpath('c')
      parser = described_class.new(node)

      expect(parser.origination.name).to eq('origination')
    end

    it 'returns nil when missing' do
      parser = described_class.new(Nokogiri::XML('<c><did/></c>').at_xpath('c'))

      expect(parser.origination).to be_nil
    end
  end

  describe '#extent' do
    it 'returns the extent node' do
      node = Nokogiri::XML('<c><did><physdesc><extent>2 boxes</extent></physdesc></did></c>').at_xpath('c')
      parser = described_class.new(node)

      expect(parser.extent.name).to eq('extent')
    end

    it 'returns nil when missing' do
      parser = described_class.new(Nokogiri::XML('<c><did/></c>').at_xpath('c'))
      expect(parser.extent).to be_nil
    end
  end

  describe '#bulk_date' do
    it 'returns the bulk unitdate' do
      node = Nokogiri::XML('<c><did><unitdate type="bulk">1950-1960</unitdate></did></c>').at_xpath('c')
      parser = described_class.new(node)

      expect(parser.bulk_date.text).to eq('1950-1960')
      expect(parser.bulk_date.name).to eq('unitdate')
    end

    it 'returns nil when absent' do
      parser = described_class.new(Nokogiri::XML('<c><did/></c>').at_xpath('c'))
      expect(parser.bulk_date).to be_nil
    end
  end

  describe '#non_bulk_date' do
    it 'returns the non-bulk unitdate' do
      node = Nokogiri::XML('<c><did><unitdate>1900</unitdate><unitdate type="bulk">1950</unitdate></did></c>')
                     .at_xpath('c')
      parser = described_class.new(node)
      expect(parser.non_bulk_date.text).to eq('1900')
      expect(parser.non_bulk_date.name).to eq('unitdate')
    end

    it 'ignores bulk dates' do
      node = Nokogiri::XML('<c><did><unitdate type="bulk">1950</unitdate></did></c>').at_xpath('c')
      parser = described_class.new(node)

      expect(parser.non_bulk_date).to be_nil
    end
  end

  describe '#unittitle' do
    it 'returns the unittitle node' do
      node = Nokogiri::XML('<c><did><unittitle>Series I</unittitle></did></c>').at_xpath('c')
      parser = described_class.new(node)

      expect(parser.unittitle.name).to eq('unittitle')
    end

    it 'returns nil when missing' do
      parser = described_class.new(Nokogiri::XML('<c><did/></c>').at_xpath('c'))
      expect(parser.unittitle).to be_nil
    end
  end

  describe '#container' do
    it 'returns all container nodes' do
      node = Nokogiri::XML(<<~XML).at_xpath('c')
        <c>
          <did>
            <container>Box 1</container>
            <container>Folder 2</container>
          </did>
        </c>
      XML

      parser = described_class.new(node)

      expect(parser.container.map(&:text)).to eq(['Box 1', 'Folder 2'])
    end

    it 'returns an empty nodeset when none exist' do
      parser = described_class.new(Nokogiri::XML('<c><did/></c>').at_xpath('c'))
      expect(parser.container).to be_empty
    end
  end

  describe '#descriptions' do
    it 'returns all descriptive nodes' do
      node = Nokogiri::XML(<<~XML).at_xpath('c')
        <c>
          <scopecontent/>
          <bioghist/>
          <odd/>
        </c>
      XML

      parser = described_class.new(node)
      expect(parser.descriptions.map(&:name)).to eq %w[scopecontent bioghist odd]
    end

    it 'uses the expected xpath' do
      node = Nokogiri::XML('<c/>').at_xpath('c')
      xpath = 'bioghist | arrangement | scopecontent | odd | relatedmaterial | userestrict | altformavail'
      allow(node).to receive(:xpath).and_return([])
      expect(node).to receive(:xpath).with(xpath)
      described_class.new(node).descriptions
    end
  end

  describe '#identifications' do
    it 'returns identification nodes under did' do
      node = Nokogiri::XML(<<~XML).at_xpath('c')
        <c>
          <did>
            <physdesc/>
            <physloc/>
          </did>
        </c>
      XML

      parser = described_class.new(node)
      expect(parser.identifications.map(&:name)).to eq %w[physdesc physloc]
    end

    it 'uses the expected xpath' do
      node = Nokogiri::XML('<c/>').at_xpath('c')
      xpath = 'did/physdesc | did/materialspec | did/physloc'
      allow(node).to receive(:xpath).and_return([])
      expect(node).to receive(:xpath).with(xpath)
      described_class.new(node).identifications
    end
  end

  describe '#digital_objects' do
    it 'returns dao elements under did and directly under the component' do
      node = Nokogiri::XML(<<~XML).at_xpath('c')
        <c>
          <did>
            <dao href="one"/>
          </did>
          <dao href="two"/>
        </c>
      XML

      parser = described_class.new(node)

      expect(parser.digital_objects.map { |dao| dao.attr('href') }).to contain_exactly('one', 'two')
    end

    it 'returns an empty nodeset when none exist' do
      parser = described_class.new(Nokogiri::XML('<c/>').at_xpath('c'))

      expect(parser.digital_objects).to be_empty
    end
  end

  describe '#first_child' do
    it 'returns the first inventory child' do
      node = Nokogiri::XML(<<~XML).at_xpath('c')
        <c>
          <c02 id="one"/>
          <c02 id="two"/>
        </c>
      XML

      parser = described_class.new(node)

      expect(parser.first_child['id']).to eq('one')
    end

    it 'returns nil when there are no children' do
      parser = described_class.new(Nokogiri::XML('<c/>').at_xpath('c'))

      expect(parser.first_child).to be_nil
    end
  end

  describe '#additional_metadata?' do
    it 'returns true when descriptions exist' do
      parser = described_class.new(Nokogiri::XML('<c><scopecontent/></c>').at_xpath('c'))

      expect(parser.additional_metadata?).to be true
    end

    it 'returns true when identifications exist' do
      parser = described_class.new(Nokogiri::XML('<c><did><physloc/></did></c>').at_xpath('c'))
      expect(parser.additional_metadata?).to be true
    end

    it 'returns true when digital objects exist' do
      parser = described_class.new(Nokogiri::XML('<c><dao/></c>').at_xpath('c'))
      expect(parser.additional_metadata?).to be true
    end

    it 'returns false when no additional metadata exists' do
      parser = described_class.new(Nokogiri::XML('<c/>').at_xpath('c'))
      expect(parser.additional_metadata?).to be false
    end
  end
end
