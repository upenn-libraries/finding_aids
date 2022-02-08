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

    it 'returns bioghist node' do
      expect(parsed_ead.bioghist).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'returns scope_content node' do
      expect(parsed_ead.scopecontent).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'returns dsc node' do
      expect(parsed_ead.dsc).to be_an_instance_of Nokogiri::XML::Element
    end
  end
end
