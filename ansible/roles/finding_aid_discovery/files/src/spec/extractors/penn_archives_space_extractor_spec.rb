# frozen_string_literal: true

require 'rails_helper'

describe PennArchivesSpaceExtractor do
  let(:endpoint) { build :endpoint, :penn_aspace_harvest }
  let(:extractor) { described_class.new(endpoint:, api: api_client) }
  let(:api_client) do
    client = instance_double(PennArchivesSpaceExtractor::ArchivesSpaceApi)
    allow(client).to receive(:all_resource_ids).and_return(['test'])
    allow(client).to receive(:resource_ead_xml).with('test').and_return('FAKE EAD XML')
    client
  end

  describe '#files' do
    subject(:files) { extractor.files }

    it 'responds to enumerable methods' do
      expect(files).to respond_to :each, :each_slice, :map, :first
    end

    it 'returns accurate count from test file' do
      expect(files.count).to eq 1
    end

    it 'returns an Array of PennArchivesSpaceFiles with XML content' do
      expect(files.first).to be_an_instance_of PennArchivesSpaceExtractor::PennArchivesSpaceFile
      expect(files.first.xml).to eq 'FAKE EAD XML'
    end

    it 'returns PennArchivesSpaceFile objects with properly derived IDs' do
      expect(files.map(&:id)).to match_array %w[test]
    end

    it 'returns PennArchivesSpaceFile objects with properly derived source IDs' do
      expect(files.map(&:source_id)).to match_array %w[test]
    end
  end
end
