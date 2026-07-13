# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  describe '.collection_guides' do
    before do
      allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
        { 'Test Repo' => ['Featured A', 'Featured B'] +
                         (0..7).map { |i| "Featured #{i}" } }
      )
    end

    it 'returns featured collection records' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
      expect(guides.first.title).to eq('Featured A')
    end

    it 'places featured picks before backfill' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
        { title: 'Backfill-A', repository: 'Test Repo' }
      ])

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(%w[Featured\ A Backfill-A])
    end

    it 'backfills up to 8 total when fewer featured picks exist' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')
      backfill = ('A'..'G').map { |l| { title: "Backfill-#{l}", repository: 'Test Repo' } }
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return(backfill)

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'skips backfill when 8 or more featured picks exist' do
      expect(RepositoryQueries).not_to receive(:random_titles)
      8.times { |i| create(:featured_collection, title: "Featured #{i}", repository: 'Test Repo') }

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'excludes featured pick titles from backfill' do
      create(:featured_collection, title: 'Featured A', repository: 'Test Repo')
      create(:featured_collection, title: 'Featured B', repository: 'Test Repo')

      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
                                                                                      { title: 'Featured A',
                                                                                        repository: 'Test Repo' },
                                                                                      { title: 'Unique',
                                                                                        repository: 'Test Repo' }
                                                                                    ])

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(['Featured A', 'Featured B', 'Unique'])
    end
  end
end
