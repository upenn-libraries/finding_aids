# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  before do
    allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
      { 'Test Repo' => ['Featured A',  'Featured 0', 'Featured 1', 'Featured 2',
                         'Featured 3', 'Featured 4', 'Featured 5', 'Featured 6',
                         'Featured 7', 'Featured 8', 'Featured 9'] }
    )
  end

  describe '.collection_guides' do
    it 'returns featured collection records' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
      expect(guides.first.title).to eq('Featured A')
    end

    it 'limits to 8 most recent featured collections' do
      10.times { |i| create(:featured_collection, title: "Featured #{i}", repository: 'Test Repo') }

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
      expect(guides.first.title).to eq('Featured 0')
      expect(guides.last.title).to eq('Featured 7')
    end
  end
end
