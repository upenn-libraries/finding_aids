# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  before do
    allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
      { 'Test Repo' => ['Featured A'] + (1..10).map { |i| "Test Collection #{i}" } }
    )
  end

  describe '.collection_guides' do
    it 'returns featured collection records' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
      expect(guides.first.title).to eq('Featured A')
    end

    it 'limits to the featured collections max' do
      create_list(:featured_collection, 10, repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides.length).to eq(HomepageData::MAX_GUIDES)
    end
  end
end
