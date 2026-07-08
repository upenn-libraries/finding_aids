# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  before do
    # Reset memoized instance variables between tests
    described_class.instance_variable_set(:@collection_guides, nil)
    described_class.instance_variable_set(:@repositories, nil)
  end

  describe '.collection_guides' do
    it 'returns an array of CollectionGuide objects' do
      guides = described_class.collection_guides

      expect(guides).to all(be_a(HomepageData::CollectionGuide))
    end

    it 'includes guide identifiers from the YAML file' do
      guides = described_class.collection_guides

      expect(guides.map(&:identifier)).to include('Haverford_HC.MC.856')
    end

    it 'includes guide names from the YAML file' do
      guides = described_class.collection_guides

      expect(guides.map(&:name)).to include('John Wilbur papers')
    end

    context 'when YAML file is missing' do
      before do
        allow(YAML).to receive(:safe_load_file).and_raise(Errno::ENOENT)
      end

      it 'returns an empty array' do
        expect(described_class.collection_guides).to eq([])
      end

      it 'logs a warning' do
        expect(Rails.logger).to receive(:warn).with(/missing or malformed/)
        described_class.collection_guides
      end
    end

    context 'when YAML is malformed' do
      before do
        allow(YAML).to receive(:safe_load_file).and_raise(Psych::SyntaxError)
      end

      it 'returns an empty array' do
        expect(described_class.collection_guides).to eq([])
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

    it 'includes repository counts from the YAML file' do
      repos = described_class.repositories

      expect(repos.map(&:count)).to include(2065)
    end

    context 'when YAML file is missing' do
      before do
        allow(YAML).to receive(:safe_load_file).and_raise(Errno::ENOENT)
      end

      it 'returns an empty array' do
        expect(described_class.repositories).to eq([])
      end
    end
  end
end
