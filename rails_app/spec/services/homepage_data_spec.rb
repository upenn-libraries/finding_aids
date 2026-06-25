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

  # Collection guides (database-backed) -------------------------------------

  describe '.collection_guides' do
    it 'returns FeaturedCollection records' do
      FeaturedCollection.create!(title: 'Test Guide', repository: 'Test Repo', active: true)

      guides = described_class.collection_guides

      expect(guides).to all(be_a(FeaturedCollection))
    end

    it 'returns only active collections' do
      FeaturedCollection.create!(title: 'Active', repository: 'Repo', active: true)
      FeaturedCollection.create!(title: 'Inactive', repository: 'Repo', active: false)

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to include('Active')
      expect(guides.map(&:title)).not_to include('Inactive')
    end

    it 'returns at most 8 collections' do
      10.times { |i| FeaturedCollection.create!(title: "Guide #{i}", repository: 'Repo', active: true) }

      guides = described_class.collection_guides

      expect(guides.length).to eq(8)
    end

    it 'orders by position' do
      FeaturedCollection.create!(title: 'Second', repository: 'Repo', position: 2, active: true)
      FeaturedCollection.create!(title: 'First', repository: 'Repo', position: 1, active: true)

      guides = described_class.collection_guides

      expect(guides.map(&:title)).to eq(%w[First Second])
    end
  end

  # Repositories ------------------------------------------------------------

  describe '.repositories' do
    before do
      allow(RepositoryQueries).to receive_messages(facet_counts: facet_data, addresses: address_data)
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
    end

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

      it 'returns nil coordinates' do
        repos = described_class.repositories
        haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }

        expect(haverford.lat).to be_nil
        expect(haverford.lng).to be_nil
      end
    end

    context 'when geocoding returns no results' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it 'returns nil coordinates' do
        repos = described_class.repositories
        haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }

        expect(haverford.lat).to be_nil
        expect(haverford.lng).to be_nil
      end
    end

    context 'when geocoding raises an error' do
      before do
        allow(Geocoder).to receive(:search).and_raise(Geocoder::Error, 'rate limited')
      end

      it 'returns nil coordinates' do
        repos = described_class.repositories
        haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }

        expect(haverford.lat).to be_nil
        expect(haverford.lng).to be_nil
      end
    end

    context 'when the address lookup fails' do
      before do
        allow(RepositoryQueries).to receive(:addresses).and_raise(StandardError, 'Solr error')
      end

      it 'returns nil coordinates' do
        repos = described_class.repositories
        haverford = repos.find { |r| r.slug == 'haverford-college-quaker-special-collections' }

        expect(haverford.lat).to be_nil
        expect(haverford.lng).to be_nil
      end
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
