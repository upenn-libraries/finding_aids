# frozen_string_literal: true

require 'rails_helper'

describe ASpaceExtractor do
  let(:endpoint) { build(:endpoint, :aspace_harvest) }
  let(:extractor) { described_class.new(endpoint: endpoint) }
  let(:aspace_service) do
    client = instance_double(ASpaceService)
    allow(client).to receive(:all_resource_ids).and_return(['test'])
    allow(client).to receive(:resource_ead_xml).with('test').and_return('FAKE EAD XML')
    client
  end

  before do
    allow(ASpaceService).to receive(:new).with(
      aspace_instance: endpoint.aspace_instance,
      repository_id: endpoint.aspace_repo_id
    ).and_return(aspace_service)
  end

  describe '#files' do
    subject(:files) { extractor.files }

    it 'responds to enumerable methods' do
      expect(files).to respond_to :each, :each_slice, :map, :first
    end

    it 'returns accurate count from test file' do
      expect(files.count).to eq 1
    end

    it 'returns an Array of ASpaceFiles with XML content' do
      expect(files.first).to be_an_instance_of ASpaceExtractor::ASpaceFile
      expect(files.first.xml).to eq 'FAKE EAD XML'
    end

    it 'returns ASpaceFile objects with properly derived IDs' do
      expect(files.map(&:id)).to match_array %w[test]
    end

    it 'returns ASpaceFile objects with properly derived source IDs' do
      expect(files.map(&:source_id)).to match_array %w[test]
    end
  end
end
