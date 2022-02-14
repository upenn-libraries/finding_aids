# frozen_string_literal: true

require 'rails_helper'

describe SolrDocument do
  subject(:doc) { described_class.new(xml_ss: xml) }

  let(:xml) { file_fixture('ead/penn_museum_ead_1.xml').read }

  it 'creates a ParsedEad' do
    expect(doc.parsed_ead).to be_an_instance_of SolrDocument::ParsedEad
  end

  context 'when using ParsedEad object' do
    let(:parsed_ead) { doc.parsed_ead }

    it 'returns dsc node' do
      expect(parsed_ead.dsc).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'does not respond to arbitrary method calls' do
      expect(parsed_ead).not_to respond_to :arbitrary
    end

    it 'responds to method calls for defined sections' do
      SolrDocument::ParsedEad::OTHER_SECTIONS.each do |section|
        expect(parsed_ead).to respond_to section
      end
    end

    it 'returns Nokogiri nodes for sections present in the EAD archdesc' do
      %w[bioghist scopecontent].each do |section|
        expect(parsed_ead.send(section).name).to eq section
      end
    end
  end
end
