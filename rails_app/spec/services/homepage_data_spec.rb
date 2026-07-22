# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  let(:cache) { Geocoding::Cache.new }
  let(:coords) do
    {
      haverford: { lat: 40.0087, lng: -75.3068 },
      hsp: { lat: 39.9496, lng: -75.1504 }
    }
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

  before do
    described_class.instance_variable_set(:@repositories, nil)
    described_class.instance_variable_set(:@repositories_json, nil)
    described_class.instance_variable_set(:@collection_guides, nil)
  end

  shared_context 'with solr stubs' do
    before do
      allow(RepositoryQueries).to receive_messages(facet_counts: facet_data, addresses: address_data)
    end
  end

  describe '.collection_guides' do
    before do
      allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
        'Test Repo' => ['Featured A', 'Featured B'] + (1..10).map { |i| "Test Collection #{i}" }
      )
    end

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

  describe '.repositories' do
    include_context 'with solr stubs'

    it 'builds Repository structs' do
      cache.store('Haverford College Quaker & Special Collections', **coords[:haverford])
      cache.store('Historical Society of Pennsylvania', **coords[:hsp])

      repos = described_class.repositories(cache: cache)
      expect(repos).to all(be_a(HomepageData::Repository))
    end

    it 'reads coordinates from cache' do
      cache.store('Haverford College Quaker & Special Collections', **coords[:haverford])

      repos = described_class.repositories(cache: cache)
      haverford = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(haverford.lat).to eq(coords[:haverford][:lat])
      expect(haverford.lng).to eq(coords[:haverford][:lng])
    end

    it 'generates slugs' do
      repos = described_class.repositories(cache: cache)
      expect(repos.map(&:slug)).to include('haverford-college-quaker-special-collections')
    end

    it 'returns nil coordinates when address is missing' do
      allow(RepositoryQueries).to receive(:addresses).and_return({})
      repos = described_class.repositories(cache: cache)
      haverford = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(haverford.lat).to be_nil
    end

    it 'returns nil coordinates when cache has FAILED entry' do
      cache.store_failure('Haverford College Quaker & Special Collections')

      repos = described_class.repositories(cache: cache)
      haverford = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(haverford.lat).to be_nil
    end
  end
end
