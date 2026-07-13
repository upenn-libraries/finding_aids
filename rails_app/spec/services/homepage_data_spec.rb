# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  describe '.collection_guides' do
    before do
      allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
        { 'Test Repo' => ['Spotlight', 'Also Spotlight'] +
                         (0..7).map { |i| "Spotlight #{i}" } }
      )
    end

    it 'returns featured collection records' do
      create(:featured_collection, title: 'Spotlight', repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
      expect(guides.first.title).to eq('Spotlight')
    end

    it 'places spotlights before backfill' do
      create(:featured_collection, title: 'Spotlight', repository: 'Test Repo')
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
                                                                                      { title: 'Backfill-A',
                                                                                        repository: 'Test Repo' }
                                                                                    ])

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(%w[Spotlight Backfill-A])
    end

    it 'backfills up to 8 total when fewer spotlights exist' do
      create(:featured_collection, title: 'Spotlight', repository: 'Test Repo')
      backfill = ('A'..'G').map { |l| { title: "Backfill-#{l}", repository: 'Test Repo' } }
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return(backfill)

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'skips backfill when 8 or more spotlights exist' do
      expect(RepositoryQueries).not_to receive(:random_titles)
      8.times { |i| create(:featured_collection, title: "Spotlight #{i}", repository: 'Test Repo') }

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'excludes spotlight titles from backfill' do
      create(:featured_collection, title: 'Spotlight', repository: 'Test Repo')
      create(:featured_collection, title: 'Also Spotlight', repository: 'Test Repo')

      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
                                                                                      { title: 'Spotlight',
                                                                                        repository: 'Test Repo' },
                                                                                      { title: 'Unique',
                                                                                        repository: 'Test Repo' }
                                                                                    ])

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(['Spotlight', 'Also Spotlight', 'Unique'])
    end
  end
end
