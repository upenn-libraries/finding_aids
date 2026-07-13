# frozen_string_literal: true

require 'rails_helper'

describe Geocoding::Service do
  subject(:service) { described_class.new(cache: cache, api_delay: 0) }

  let(:cache) { Geocoding::Cache.new }

  let(:geocoder_result) do
    Struct.new(:latitude, :longitude, :coordinates).new(40.0087, -75.3068, [40.0087, -75.3068])
  end

  before do
    cache.instance_variable_set(:@load, {})
    FileUtils.rm_f(Geocoding::Cache::CACHEFILE)
  end

  describe '#coordinates_for' do
    it 'returns blank when address is nil' do
      expect(service.coordinates_for('Test', nil)).to eq(lat: nil, lng: nil)
    end

    it 'returns blank when address is blank' do
      expect(service.coordinates_for('Test', '')).to eq(lat: nil, lng: nil)
    end

    it 'returns cached coordinates when present' do
      cache.store('Test', lat: 39.95, lng: -75.16)

      expect(service.coordinates_for('Test', '123 Main St')).to eq(lat: 39.95, lng: -75.16)
    end

    it 'returns blank when cache has FAILED entry' do
      cache.store('Test', failed: true)

      expect(service.coordinates_for('Test', '123 Main St')).to eq(lat: nil, lng: nil)
    end

    it 'returns blank when address is uncached (no API call)' do
      expect(Geocoder).not_to receive(:search)
      expect(service.coordinates_for('Test', '123 Main St')).to eq(lat: nil, lng: nil)
    end
  end

  describe '#geocode' do
    it 'returns coordinates on success' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
      result = service.geocode('370 Lancaster Ave, Haverford, PA')
      expect(result).to eq(lat: 40.0087, lng: -75.3068)
    end

    it 'returns nil when geocoder raises' do
      allow(Geocoder).to receive(:search).and_raise(StandardError, 'boom')
      expect(service.geocode('bad address')).to be_nil
    end

    it 'returns nil when coordinates are nil' do
      nil_result = Struct.new(:latitude, :longitude, :coordinates).new(nil, nil, [nil, nil])
      allow(Geocoder).to receive(:search).and_return([nil_result])
      expect(service.geocode('nowhere')).to be_nil
    end
  end

  describe '#refresh!' do
    it 'geocodes uncached addresses and stores them' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])
      count = service.refresh!('Haverford' => '370 Lancaster Ave, Haverford, PA')
      expect(count).to eq(1)
      expect(cache.load['Haverford']).to eq(lat: 40.0087, lng: -75.3068)
    end

    it 'skips cached addresses' do
      cache.store('Done', lat: 39.95, lng: -75.16)
      allow(Geocoder).to receive(:search).and_return([geocoder_result])

      count = service.refresh!('Done' => 'Some address', 'New' => 'Other address')
      expect(count).to eq(1)
    end

    it 'skips failed addresses' do
      cache.store('Failed', failed: true)
      expect(Geocoder).not_to receive(:search)

      count = service.refresh!('Failed' => 'Bad address')
      expect(count).to eq(0)
    end

    it 'stores failed entry when geocoding returns nil' do
      allow(Geocoder).to receive(:search).and_return([])
      count = service.refresh!('NoResults' => 'Nowhere')
      expect(count).to eq(1)
      expect(cache.load['NoResults']).to eq(lat: nil, lng: nil, _failed: true)
    end

    it 'stores failed entry when geocoder raises' do
      allow(Geocoder).to receive(:search).and_raise(StandardError, 'boom')
      count = service.refresh!('Error' => 'Bad address')
      expect(count).to eq(1)
      expect(cache.load['Error']).to eq(lat: nil, lng: nil, _failed: true)
    end

    it 'skips blank addresses' do
      expect(Geocoder).not_to receive(:search)
      count = service.refresh!('Blank' => '')
      expect(count).to eq(0)
    end

    it 'persists cache when updates occurred' do
      allow(Geocoder).to receive(:search).and_return([geocoder_result])

      expect { service.refresh!('A' => 'addr') }
        .to change { File.exist?(Geocoding::Cache::CACHEFILE) }.from(false).to(true)
    end
  end
end
