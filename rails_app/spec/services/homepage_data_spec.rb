# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  before do
    described_class.instance_variable_set(:@collection_guides, nil)
    described_class.instance_variable_set(:@repositories, nil)
    described_class.instance_variable_set(:@coordinates_cache, nil)
  end

  let(:geocoder_result) do
    Struct.new(:latitude, :longitude, :coordinates).new(40.0087, -75.3068, [40.0087, -75.3068])
  end

  let(:facet_data) do
    [
      { name: 'Haverford College Quaker & Special Collections', count: 2100 },
      { name: 'Historical Society of Pennsylvania', count: 300 }
    ]
  end

  let(:address_data) do
    {
      'Haverford College Quaker & Special Collections' => '370 Lancaster Ave, Haverford, PA 19041',
      'Historical Society of Pennsylvania' => '1300 Locust St, Philadelphia, PA 19107'
    }
  end

  shared_context 'with solr and geocoder stubs' do
    before do
      allow(RepositoryQueries).to receive_messages(facet_counts: facet_data, addresses: address_data)
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
    end
  end

  shared_examples 'nil coordinates' do
    it 'returns nil coordinates' do
      repos = described_class.repositories
      repo = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }

      expect(repo.lat).to be_nil
      expect(repo.lng).to be_nil
    end
  end

  # Collection guides (spotlights + backfill) ------------------------------

  describe '.collection_guides' do
    before do
      allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
        { 'Test Repo' => ['Spotlight', 'Also Spotlight'] +
                         (0..7).map { |i| "Spotlight #{i}" } }
      )
    end

    it 'returns spotlight collections' do
      FeaturedCollection.create!(title: 'Spotlight', repository: 'Test Repo')

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
      expect(guides.first.title).to eq('Spotlight')
    end

    it 'places spotlights before backfill' do
      FeaturedCollection.create!(title: 'Spotlight', repository: 'Test Repo')
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
        { title: 'Backfill-A', repository: 'Test Repo' }
      ])

      guides = described_class.collection_guides

      expect(guides.length).to eq(2)
      expect(guides.first.title).to eq('Spotlight')
      expect(guides.last.title).to eq('Backfill-A')
    end

    it 'backfills up to 8 total when fewer spotlights exist' do
      FeaturedCollection.create!(title: 'Spotlight', repository: 'Test Repo')
      backfill = ('A'..'G').map { |l| { title: "Backfill-#{l}", repository: 'Test Repo' } }
      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return(backfill)

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'skips backfill when 8 or more spotlights exist' do
      allow(RepositoryQueries).to receive(:random_titles)
      8.times { |i| FeaturedCollection.create!(title: "Spotlight #{i}", repository: 'Test Repo') }

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
      expect(RepositoryQueries).not_to have_received(:random_titles)
    end

    it 'excludes spotlight titles from backfill' do
      FeaturedCollection.create!(title: 'Spotlight', repository: 'Test Repo')
      FeaturedCollection.create!(title: 'Also Spotlight', repository: 'Test Repo')

      allow(RepositoryQueries).to receive(:random_titles).with(limit: 8).and_return([
        { title: 'Spotlight', repository: 'Test Repo' },
        { title: 'Unique', repository: 'Test Repo' }
      ])

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(['Spotlight', 'Also Spotlight', 'Unique'])
    end
  end

  # Repositories ------------------------------------------------------------

  describe '.reset!' do
    include_context 'with solr and geocoder stubs'

    it 'clears memoized repositories so the next call re-fetches' do
      original = described_class.repositories
      described_class.reset!
      refreshed = described_class.repositories

      expect(refreshed.map(&:name)).to eq(original.map(&:name))
    end
  end

  describe '.repositories' do
    include_context 'with solr and geocoder stubs'

    it 'returns an array of Repository objects' do
      repos = described_class.repositories

      expect(repos).to all(be_a(HomepageData::Repository))
    end

    it 'builds Repository structs from query data' do
      repos = described_class.repositories

      haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }
      expect(haverford.name).to eq('Haverford College Quaker & Special Collections')
      expect(haverford.count).to eq(2100)
    end

    it 'geocodes coordinates from addresses' do
      repos = described_class.repositories

      haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }
      expect(haverford.lat).to eq(40.0087)
      expect(haverford.lng).to eq(-75.3068)
    end

    it 'generates a slug from the name' do
      repos = described_class.repositories

      expect(repos.map(&:slug)).to include('haverford-college-quaker-special-collections')
    end

    context 'when a repository has no address' do
      before do
        allow(RepositoryQueries).to receive(:addresses).and_return({})
      end

      include_examples 'nil coordinates'
    end

    context 'when geocoding returns no results' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      include_examples 'nil coordinates'
    end

    context 'when geocoding raises an error' do
      before do
        allow(Geocoder).to receive(:search).and_raise(Geocoder::Error, 'rate limited')
      end

      include_examples 'nil coordinates'
    end

    context 'when the address lookup fails' do
      before do
        allow(RepositoryQueries).to receive(:addresses).and_raise(StandardError, 'Solr error')
      end

      include_examples 'nil coordinates'
    end

    context 'when Solr is unavailable' do
      before do
        allow(RepositoryQueries).to receive(:facet_counts).and_raise(SocketError, 'Connection refused')
      end

      it 'lets the error propagate' do
        expect { described_class.repositories }.to raise_error(SocketError)
      end
    end
  end
end
