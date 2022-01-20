# frozen_string_literal: true

require 'rails_helper'

describe Endpoint do
  context 'basic attributes' do
    let(:index_endpoint) { build(:endpoint, :index_harvest) }

    it 'has no validation errors' do
      expect(index_endpoint.valid?).to be true
    end

    it 'has functioning JSON accessor methods' do
      expect(index_endpoint.url).to eq 'https://www.test.com/pacscl'
      expect(index_endpoint.type).to eq 'index'
    end
  end

  describe '#slug' do
    let(:endpoint) { build(:endpoint) }

    it 'must be present' do
      endpoint.slug = nil
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:slug]).to include('can\'t be blank')
    end

    it 'must be unique' do
      new_endpoint = create(:endpoint, :index_harvest)
      endpoint.slug = new_endpoint.slug
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:slug]).to include('has already been taken')
    end

    it 'must only contain lowercase letters and underscores' do
      endpoint.slug = 'PLAC_DF'
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:slug]).to include('is invalid')
    end
  end

  describe '#harvest_config' do
    let(:endpoint) { build(:endpoint) }

    it 'must include url' do
      endpoint.harvest_config = { url: '', type: 'index' }
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:url]).to include('can\'t be blank')
    end

    it 'must include valid type' do
      endpoint.harvest_config = { url: 'https://example.com', type: 'gopher' }
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:type]).to include 'is not included in the list'
    end
  end

  describe '#harvest_results' do
    context 'when harvest has never been run' do
      let(:endpoint) do
        build(:endpoint, :index_harvest)
      end

      it 'return status as nil' do
        expect(endpoint.last_harvest.status).to be nil
      end
    end

    context 'when harvest complete' do
      let(:endpoint) do
        build(:endpoint, :index_harvest, :complete_harvest)
      end

      it 'returned status is "completed"' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::COMPLETE
        expect(endpoint.last_harvest.complete?).to be true
      end
    end

    context 'when harvest failed' do
      let(:endpoint) do
        build(:endpoint, :index_harvest, :failed_harvest)
      end

      it 'returned status is failed' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::FAILED
        expect(endpoint.last_harvest.failed?).to be true
      end

      it 'lists expected errors' do
        expect(endpoint.last_harvest.errors).to match_array ['Problem extracting xml ead links from endpoint']
      end
    end

    context 'when harvest partially complete' do
      let(:endpoint) do
        build(:endpoint, :index_harvest, :partial_harvest)
      end

      it 'returned status is partial' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::PARTIAL
        expect(endpoint.last_harvest.partial?).to be true
      end

      it 'lists expected problem files' do
        expect(
          endpoint.last_harvest.problem_files
        ).to match_array([
                           { 'filename' => '', 'status' => 'failed', 'errors' => ['Problem downloading XML file'] }
                         ])
      end
    end

    context 'when files were removed during harvest' do
      let(:endpoint) do
        build(:endpoint, :index_harvest, :harvest_with_removals)
      end

      it 'removals returns true' do
        expect(endpoint.last_harvest.removals?).to be true
      end

      it 'list files that were removed' do
        expect(
          endpoint.last_harvest.removed_files
        ).to match_array([
                           { 'id' => 'removed-record-1', 'status' => 'removed' },
                           { 'id' => 'removed-record-2', 'status' => 'removed' }
                         ])
      end
    end
  end
end
