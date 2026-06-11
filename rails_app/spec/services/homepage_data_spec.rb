# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  describe '.collection_guides' do
    it 'returns an array of CollectionGuide objects' do
      guides = described_class.collection_guides

      expect(guides).to all(be_a(HomepageData::CollectionGuide))
    end

    it 'includes guide names from the YAML file' do
      guides = described_class.collection_guides

      expect(guides.map(&:name)).to include('John Wilbur papers')
    end

    describe 'memoization' do
      before do
        described_class.remove_instance_variable(:@collection_guides)
        allow(YAML).to receive(:safe_load_file).and_call_original
      end

      it 'parses YAML only on the first call' do
        expect(YAML).to receive(:safe_load_file).once.and_call_original
        described_class.collection_guides
        described_class.collection_guides
      end
    end
  end

  describe '.repositories' do
    it 'returns an array of Repository objects' do
      repos = described_class.repositories

      expect(repos).to all(be_a(HomepageData::Repository))
    end

    it 'includes repository slugs from the YAML file' do
      repos = described_class.repositories

      expect(repos.map(&:slug)).to include('haverford-quaker')
    end

    describe 'memoization' do
      before do
        described_class.remove_instance_variable(:@repositories)
      end

      it 'parses YAML only on the first call' do
        expect(YAML).to receive(:safe_load_file).once.and_call_original
        described_class.repositories
        described_class.repositories
      end
    end
  end

  describe 'error handling' do
    before do
      described_class.remove_instance_variable(:@collection_guides) \
        if described_class.instance_variable_defined?(:@collection_guides)

      stub_const('HomepageData::COLLECTION_GUIDES_PATH',
                 Rails.root.join('tmp/nonexistent_test_file.yml'))
    end

    it 'returns an empty array when the YAML file is missing' do
      expect(Rails.logger).to receive(:warn).with(/missing or malformed/)
      expect(described_class.collection_guides).to eq([])
    end

    it 'memoizes the empty result' do
      expect(Rails.logger).to receive(:warn).once
      described_class.collection_guides
      described_class.collection_guides
    end
  end
end
