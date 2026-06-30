# frozen_string_literal: true

require 'rails_helper'

describe HomepageData do
  before do
    described_class.instance_variable_set(:@collection_guides, nil)
    described_class.instance_variable_set(:@repositories, nil)
    described_class.instance_variable_set(:@coordinates, nil)
    FileUtils.rm_f(HomepageData::CACHEFILE)
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

  shared_context 'with solr stubs' do
    before do
      allow(RepositoryQueries).to receive_messages(facet_counts: facet_data, addresses: address_data)
    end
  end

  shared_context 'with geocoder stub' do
    before do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
    end
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
    include_context 'with solr stubs'
    include_context 'with geocoder stub'

    it 'builds Repository structs' do
      repos = described_class.repositories
      expect(repos).to all(be_a(HomepageData::Repository))
    end

    it 'geocodes coordinates' do
      repos = described_class.repositories
      haverford = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(haverford.lat).to eq(40.0087)
      expect(haverford.lng).to eq(-75.3068)
    end

    it 'generates slugs' do
      repos = described_class.repositories
      expect(repos.map(&:slug)).to include('haverford-college-quaker-special-collections')
    end

    it 'returns nil coordinates when geocoding fails' do
      allow(Geocoder).to receive(:search).and_raise(StandardError, 'boom')
      repos = described_class.repositories
      repo = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(repo.lat).to be_nil
      expect(repo.lng).to be_nil
    end

    it 'returns nil when address is missing' do
      allow(RepositoryQueries).to receive(:addresses).and_return({})
      repos = described_class.repositories
      repo = repos.find { |r| r.name == 'Haverford College Quaker & Special Collections' }
      expect(repo.lat).to be_nil
    end
  end

  describe '.reset!' do
    include_context 'with solr stubs'
    include_context 'with geocoder stub'

    it 'clears memoized repositories' do
      original = described_class.repositories
      described_class.reset!
      expect(described_class.repositories.map(&:name)).to eq(original.map(&:name))
    end
  end
end
