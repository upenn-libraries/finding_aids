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

  it 'creates a ParsedEad' do
    expect(doc.parsed_ead).to be_an_instance_of SolrDocument::ParsedEad
  end

  it 'returns expected topics in hash form' do
    expect(doc.topics_hash.keys).to match_array(
      %i[places_ssim people_ssim subjects_ssim corpnames_ssim occupations_ssim]
    )
    expect(doc.topics_hash[:places_ssim]).to eq ['Philadelphia']
  end

  describe '#penn_item?' do
    let(:fields) { { repository_name_component_1_ssi: repo } }

    context 'with a penn item' do
      let(:repo) { 'University of Pennsylvania' }

      it { is_expected.to be_a_penn_item }
    end

    context 'with a non-Penn item' do
      let(:repo) { 'Princeton University' }

      it { is_expected.not_to be_a_penn_item }
    end
  end

  describe '#language_note' do
    context 'without text content' do
      it 'returns a blank value' do
        expect(doc.language_note).to be_blank
      end
    end

    context 'with text content' do
      let(:xml) do
        <<~XML
          <ead>
            <archdesc>
              <did>
                <langmaterial>
                  Mostly in <language langcode="eng">English</language>, but some materials contain Esperanto.
                </langmaterial>
              </did>
            </archdesc>
          </ead>
        XML
      end

      it 'parses the expected data' do
        expect(doc.language_note).to eq 'Mostly in English, but some materials contain Esperanto.'
      end
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
      SolrDocument::ParsedEad::OTHER_SECTIONS.each do |section|
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
