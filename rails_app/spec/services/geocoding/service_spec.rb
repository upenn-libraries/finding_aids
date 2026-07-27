# frozen_string_literal: true

require 'rails_helper'

describe Geocoding::Service do
  subject(:service) { described_class.new(cache: cache, api_delay: 0) }

  let(:cache_path) { Rails.root.join('tmp/geocoder_cache_test.yml') }
  let(:cache) { Geocoding::Cache.new(path: cache_path) }

  let(:geocoder_result) do
    Struct.new(:latitude, :longitude, :coordinates).new(40.0087, -75.3068, [40.0087, -75.3068])
  end

  let(:coords) { { lat: 40.0087, lng: -75.3068 } }

  before do
    cache.clear!
    FileUtils.rm_f(cache_path)
  end

  describe '#coordinates_for' do
    it 'returns blank when address is nil' do
      expect(service.coordinates_for('Test', nil)).to eq(Geocoding::Cache::BLANK)
    end

    it 'returns blank when address is blank' do
      expect(service.coordinates_for('Test', '')).to eq(Geocoding::Cache::BLANK)
    end

    it 'returns cached coordinates when present' do
      cache.store('Test', **coords)

      expect(service.coordinates_for('Test', '123 Main St')).to eq(coords)
    end

    it 'returns blank when cache has failed entry' do
      cache.store_failure('Test')

      expect(service.coordinates_for('Test', '123 Main St')).to eq(Geocoding::Cache::BLANK)
    end

    it 'returns blank when address is uncached (no API call)' do
      expect(Geocoder).not_to receive(:search)
      expect(service.coordinates_for('Test', '123 Main St')).to eq(Geocoding::Cache::BLANK)
    end
  end

  describe '#geocode' do
    it 'returns a success Result with coordinates' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
      result = service.geocode('370 Lancaster Ave, Haverford, PA')
      expect(result).to have_attributes(success?: true, lat: 40.0087, lng: -75.3068)
    end

    it 'returns a failure Result when geocoder raises' do
      allow(Geocoder).to receive(:search).and_raise(StandardError, 'boom')
      result = service.geocode('bad address')
      expect(result.success?).to be false
    end

    it 'returns a failure Result when coordinates are nil' do
      nil_result = Struct.new(:latitude, :longitude, :coordinates).new(nil, nil, [nil, nil])
      allow(Geocoder).to receive(:search).and_return([nil_result])
      result = service.geocode('nowhere')
      expect(result.success?).to be false
    end
  end

  describe '#refresh!' do
    it 'geocodes uncached addresses and stores them' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
      count = service.refresh!('Haverford' => '370 Lancaster Ave, Haverford, PA')
      expect(count).to eq(1)
      expect(cache['Haverford']).to eq(coords)
    end

    it 'skips cached addresses without overwriting them' do
      cache.store('Done', lat: 39.95, lng: -75.16)
      allow(Geocoder).to receive(:search).and_return([geocoder_result])

      count = service.refresh!('Done' => 'Some address', 'New' => 'Other address')
      expect(count).to eq(1)
      expect(cache['Done']).to eq(lat: 39.95, lng: -75.16)
    end

    it 'skips failed addresses' do
      cache.store_failure('Failed')
      expect(Geocoder).not_to receive(:search)

      count = service.refresh!('Failed' => 'Bad address')
      expect(count).to eq(0)
    end

    it 'stores failed entry when geocoding returns no results' do
      allow(Geocoder).to receive(:search).and_return([])
      count = service.refresh!('NoResults' => 'Nowhere')
      expect(count).to eq(1)
      expect(cache['NoResults']).to eq(Geocoding::Cache::FAILED)
    end

    it 'stores failed entry when geocoder raises' do
      allow(Geocoder).to receive(:search).and_raise(StandardError, 'boom')
      count = service.refresh!('Error' => 'Bad address')
      expect(count).to eq(1)
      expect(cache.failed?('Error')).to be true
    end

    it 'skips blank addresses' do
      expect(Geocoder).not_to receive(:search)
      count = service.refresh!('Blank' => '')
      expect(count).to eq(0)
    end

    it 'persists cache when updates occurred' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])

      expect { service.refresh!('A' => 'addr') }
        .to change { File.exist?(cache_path) }.from(false).to(true)
    end

    it 'yields name and Result to the progress block' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
      expect { |b| service.refresh!('Repo' => '123 Main St', &b) }
        .to yield_with_args('Repo', having_attributes(success?: true))
    end
  end
end
