# frozen_string_literal: true

require 'rails_helper'
require_relative 'concerns/synchronizable_spec'

describe Endpoint do
  let(:index_endpoint) { build(:endpoint, :index_harvest) }

  it_behaves_like 'synchronizable'

  it 'has no validation errors' do
    expect(index_endpoint.valid?).to be true
  end

  it 'has functioning JSON accessor methods' do
    expect(index_endpoint.url).to eq 'https://www.test.com/pacscl'
    expect(index_endpoint.type).to eq 'index'
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

    it 'must only contain lowercase/uppercase letters and underscores' do
      endpoint.slug = 'PLAC_DF9'
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:slug]).to include('is invalid')
    end
  end

  describe '#harvest_config' do
    let(:endpoint) { build(:endpoint) }

    it 'must include valid type' do
      endpoint.harvest_config = { url: 'https://example.com', type: 'gopher' }
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:type]).to include 'is not included in the list'
    end

    context 'with index type' do
      it 'must have a URL' do
        endpoint.harvest_config = { type: 'index', url: nil }
        expect(endpoint.valid?).to be false
        expect(endpoint.errors[:harvest_config]).to include 'must have a URL provided'
      end
    end

    context 'with penn_archives_space type' do
      it 'must have a repository id' do
        endpoint.harvest_config = { type: 'penn_archives_space', repository_id: nil }
        expect(endpoint.valid?).to be false
        expect(endpoint.errors[:harvest_config]).to include 'must have a Repository ID provided'
      end
    end
  end

  describe '#harvest_results' do
    context 'when harvest has never been run' do
      let(:endpoint) do
        build(:endpoint, :index_harvest)
      end

      it 'return status as nil' do
        expect(endpoint.last_harvest.status).to be_nil
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
                           { 'id' => 'test-failed-id', 'status' => 'failed', 'errors' => ['Problem downloading file'] }
                         ])
      end
    end

    context 'when files were removed during harvest' do
      let(:endpoint) do
        build(:endpoint, :index_harvest, :harvest_with_removals)
      end
      let(:removed_files) do
        [
          { 'id' => 'removed-record-1', 'status' => 'removed' },
          { 'id' => 'removed-record-2', 'status' => 'removed' }
        ]
      end

      it 'removals returns true' do
        expect(endpoint.last_harvest.removals?).to be true
      end

      it 'list files that were removed' do
        expect(endpoint.last_harvest.removed_files).to match_array(removed_files)
      end
    end
  end
end
