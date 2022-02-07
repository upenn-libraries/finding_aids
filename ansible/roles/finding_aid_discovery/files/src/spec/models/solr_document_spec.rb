# frozen_string_literal: true

require 'rails_helper'

describe SolrDocument do
  let(:xml) { file_fixture('ead/penn_museum_ead_1.xml').read }
  subject(:doc) { SolrDocument.new(xml_ss: xml) }

  it 'creates a ParsedEad' do
    expect(doc.parsed_ead).to be_an_instance_of SolrDocument::ParsedEad
  end

  context 'ParsedEad object' do
    let(:parsed_ead) { doc.parsed_ead }

    it 'returns bioghist node' do
      expect(parsed_ead.biog_hist).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'returns scope_content node' do
      expect(parsed_ead.scope_content).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'returns dsc node' do
      expect(parsed_ead.dsc).to be_an_instance_of Nokogiri::XML::Element
    end

  end
end
