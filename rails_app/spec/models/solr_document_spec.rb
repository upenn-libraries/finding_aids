# frozen_string_literal: true

require 'rails_helper'

describe SolrDocument do
  subject(:doc) { described_class.new(fields) }

  let(:xml) { file_fixture('ead/penn_museum_ead_1.xml').read }
  let(:fields) do
    { xml_ss: xml,
      places_ssim: ['Philadelphia'],
      people_ssim: ['Doe, John'],
      subjects_ssim: ['Cooking'],
      corpnames_ssim: ['University of Pennsylvania'] }
  end

  it 'creates a parsed ead' do
    expect(doc.parsed_ead).to be_an_instance_of Ead::Parsing::ArchivalDescription
  end

  it 'creates an ead extraction' do
    expect(doc.ead_extraction).to be_an_instance_of Ead::Extraction::ArchivalDescription
  end

  describe '#extract' do
    before { allow(doc.ead_extraction).to receive(:access_restrictions) }

    it 'sends the message to the ead extraction' do
      expect(doc.ead_extraction).to receive(:access_restrictions).once
      doc.extract(:access_restrictions)
    end
  end

  context 'when using ParsedEad object' do
    let(:parsed_ead) { doc.parsed_ead }

    it 'returns dsc node' do
      expect(parsed_ead.dsc).to be_an_instance_of Nokogiri::XML::Element
    end

    it 'returns did node' do
      expect(parsed_ead.did).to be_an_instance_of Nokogiri::XML::Element
      expect(parsed_ead.did.name).to eq 'did'
    end

    it 'does not respond to arbitrary method calls' do
      expect(parsed_ead).not_to respond_to :arbitrary
    end

    it 'responds to method calls for defined sections' do
      Ead::Parsing::ArchivalDescription::OTHER_SECTIONS.each do |section|
        expect(parsed_ead).to respond_to section
      end
    end

    it 'returns Nokogiri nodes for sections present in the EAD archdesc' do
      %w[bioghist scopecontent].each do |section|
        expect(parsed_ead.try(section).first.name).to eq section
      end
    end
  end
end
