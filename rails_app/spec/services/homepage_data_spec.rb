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

  # Collection guides (YAML) -------------------------------------------------

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
