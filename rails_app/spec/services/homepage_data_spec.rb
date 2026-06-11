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
  end
end
