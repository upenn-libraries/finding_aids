# frozen_string_literal: true

RSpec.describe Ead::Extraction::NodeText do
  describe '#translate' do
    it 'translates a node and removes the head when requested' do
      node = Nokogiri::XML(<<~XML).at_xpath('scopecontent')
        <scopecontent>
          <head>Scope</head>
          <p>Collection contains correspondence.</p>
        </scopecontent>
      XML

      result = described_class.translate(node: node, remove_head: true)

      expect(result).to include('<p>Collection contains correspondence.</p>')
      expect(result).not_to include('Scope')
    end

    it 'keeps the head when remove_head is false' do
      node = Nokogiri::XML(<<~XML).at_xpath('scopecontent')
        <scopecontent>
          <head>Scope</head>
          <p>Collection contains correspondence.</p>
        </scopecontent>
      XML

      result = described_class.translate(node: node, remove_head: false)

      expect(result).to include('Scope')
      expect(result).to include('<p>Collection contains correspondence.</p>')
    end

    it 'returns nil for a missing node' do
      expect(described_class.translate(node: nil)).to be_nil
    end
  end

  describe '#translate_many' do
    it 'joins multiple translated nodes' do
      nodes = Nokogiri::XML(<<~XML).xpath('//accessrestrict')
        <root>
          <accessrestrict>
            <head>Access</head>
            <p>Restricted access.</p>
          </accessrestrict>
          <accessrestrict>
            <head>Access</head>
            <p>Contact archivist.</p>
          </accessrestrict>
        </root>
      XML

      result = described_class.translate_many(nodes)

      expect(result).to include('<p>Restricted access.</p>')
      expect(result).to include('<p>Contact archivist.</p>')
    end

    it 'removes the head when remove_head is true' do
      nodes = Nokogiri::XML(<<~XML).xpath('//accessrestrict')
        <root>
          <accessrestrict>
            <head>Access</head>
            <p>Restricted access.</p>
          </accessrestrict>
          <accessrestrict>
            <head>Access</head>
            <p>Contact archivist.</p>
          </accessrestrict>
        </root>
      XML

      result = described_class.translate_many(nodes, remove_head: true)

      expect(result).not_to include('Access')
    end

    it 'keeps the head when remove_head is false' do
      nodes = Nokogiri::XML(<<~XML).xpath('//accessrestrict')
        <root>
          <accessrestrict>
            <head>Access</head>
            <p>Restricted access.</p>
          </accessrestrict>
          <accessrestrict>
            <head>Access</head>
            <p>Contact archivist.</p>
          </accessrestrict>
        </root>
      XML

      result = described_class.translate_many(nodes, remove_head: false)

      expect(result).to include('Access')
    end

    it 'returns nil for an empty nodeset' do
      node_set = Nokogiri::XML::NodeSet.new(Nokogiri::XML.parse('<ead></ead>')).xpath('archdesc')
      expect(described_class.translate_many(node_set)).to be_nil
    end
  end

  describe '#text_only' do
    it 'returns text without markup' do
      node = Nokogiri::XML(<<~XML).at_xpath('langmaterial')
        <langmaterial>
          <language>English</language>
          <language>French</language>
        </langmaterial>
      XML

      expect(described_class.text_only(node)).to eq("English\n  French")
    end

    it 'returns nil when node is missing' do
      expect(described_class.text_only(nil)).to be_nil
    end
  end

  describe '#definitions' do
    it 'creates definitions from nodes and translations' do
      nodes = Nokogiri::XML(<<~XML).xpath('//bioghist')
        <root>
          <bioghist>
            <head>Biography</head>
            <p>One was born in 1900.</p>
          </bioghist>
          <bioghist>
            <head>Biography</head>
            <p>Another was born in 1920.</p>
          </bioghist>
        </root>
      XML

      definitions = described_class.map_translations(nodes, remove_head: true) do |node, translation|
        [node.name, translation]
      end

      expect(definitions).to eq([['bioghist', "\n    \n    <p>One was born in 1900.</p>\n  "],
                                 ['bioghist', "\n    \n    <p>Another was born in 1920.</p>\n  "]])
    end

    it 'returns an empty array for no nodes' do
      expect(described_class.map_translations([])).to eq([])
    end
  end

  describe Ead::Extraction::NodeText::Definition do
    it 'stores the term and translation' do
      definition = described_class.new('bioghist', 'Some history')

      expect(definition.term).to eq('bioghist')
      expect(definition.translation).to eq('Some history')
    end
  end
end
