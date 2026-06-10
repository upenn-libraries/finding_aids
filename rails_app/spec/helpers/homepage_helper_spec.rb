# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomepageHelper, type: :helper do
  let(:data) { instance_double(HomepageData) }

  before do
    allow(HomepageData).to receive(:new).and_return(data)
  end

  describe '#sample_collection_guides' do
    let(:guides) do
      [
        OpenStruct.new(name: 'Test Guide', collection: 'Test Inst', identifier: 'T.001'),
        OpenStruct.new(name: 'Guide 2', collection: 'Inst 2', identifier: 'T.002'),
        OpenStruct.new(name: 'Guide 3', collection: 'Inst 3', identifier: 'T.003')
      ]
    end

    before do
      allow(data).to receive(:collection_guides).and_return(guides)
    end

    it 'returns the requested number of guides' do
      result = helper.sample_collection_guides(2)
      expect(result.length).to eq(2)
    end

    it 'returns all guides if count exceeds available data' do
      result = helper.sample_collection_guides(100)
      expect(result.length).to eq(3)
    end

    it 'returns objects responding to name, collection, identifier' do
      result = helper.sample_collection_guides(1)
      expect(result.first.name).to eq('Test Guide')
      expect(result.first.collection).to eq('Test Inst')
      expect(result.first.identifier).to eq('T.001')
    end
  end

  describe '#sample_repositories' do
    let(:repos) do
      [
        OpenStruct.new(name: 'Test Repo', count: 100, lat: 39.95, lng: -75.16, slug: 'test'),
        OpenStruct.new(name: 'Repo 2', count: 200, lat: 40.0, lng: -75.19, slug: 'repo2')
      ]
    end

    before do
      allow(data).to receive(:repositories).and_return(repos)
    end

    it 'returns the requested number of repos' do
      result = helper.sample_repositories(1)
      expect(result.length).to eq(1)
    end

    it 'returns objects with coordinate fields' do
      result = helper.sample_repositories(1)
      expect(result.first.lat).to eq(39.95)
      expect(result.first.lng).to eq(-75.16)
      expect(result.first.count).to eq(100)
    end
  end

  describe '#all_repositories' do
    before do
      allow(data).to receive(:repositories).and_return([OpenStruct.new(name: 'R1')])
    end

    it 'delegates to HomepageData' do
      expect(helper.all_repositories.length).to eq(1)
    end
  end

  describe '#repository_facet_path' do
    it 'builds a facet URL for the given repo name' do
      allow(helper).to receive(:search_action_path)
        .with(f: { repository_ssi: ['Test Repo'] })
        .and_return('/records?f%5Brepository_ssi%5D%5B%5D=Test+Repo')

      path = helper.repository_facet_path('Test Repo')
      expect(path).to include('repository_ssi')
    end
  end
end
