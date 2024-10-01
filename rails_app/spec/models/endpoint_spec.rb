# frozen_string_literal: true

require 'rails_helper'
require_relative 'concerns/synchronizable_spec'

describe Endpoint do
  let(:webpage_endpoint) { build(:endpoint, :webpage_harvest) }

  it_behaves_like 'synchronizable'

  it 'has no validation errors' do
    expect(webpage_endpoint.valid?).to be true
  end

  describe '#slug' do
    let(:endpoint) { build(:endpoint) }

    it 'must be present' do
      endpoint.slug = nil
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:slug]).to include('can\'t be blank')
    end

    it 'must be unique' do
      new_endpoint = create(:endpoint, :webpage_harvest)
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

  describe '#source_type' do
    let(:endpoint) { build(:endpoint) }

    it 'must be present' do
      endpoint.source_type = nil
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:source_type]).to include('can\'t be blank')
    end

    it 'must be valid source type' do
      endpoint.source_type = 'gopher'
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:source_type]).to include 'is not included in the list'
    end
  end

  describe '#webpage_url' do
    let(:endpoint) { build(:endpoint) }

    it 'must be present' do
      endpoint.source_type = Endpoint::WEBPAGE_TYPE
      expect(endpoint.valid?).to be false
      expect(endpoint.errors[:webpage_url]).to include "can't be blank"
    end
  end

  describe '#aspace_repo_id' do
    let(:endpoint) { build(:endpoint) }

    context 'with aspace source_type' do
      it 'must be present' do
        endpoint.source_type = Endpoint::ASPACE_TYPE
        endpoint.aspace_repo_id = nil
        expect(endpoint.valid?).to be false
        expect(endpoint.errors[:aspace_repo_id]).to include "can't be blank"
      end
    end
  end

  describe '#harvest_results' do
    context 'when harvest has never been run' do
      let(:endpoint) do
        build(:endpoint, :webpage_harvest)
      end

      it 'return status as nil' do
        expect(endpoint.last_harvest.status).to be_nil
      end
    end

    context 'when harvest complete' do
      let(:endpoint) do
        build(:endpoint, :webpage_harvest, :complete_harvest)
      end

      it 'returned status is "completed"' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::COMPLETE
        expect(endpoint.last_harvest.complete?).to be true
      end
    end

    context 'when harvest failed' do
      let(:endpoint) do
        build(:endpoint, :webpage_harvest, :failed_harvest)
      end

      it 'returned status is failed' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::FAILED
        expect(endpoint.last_harvest.failed?).to be true
      end

      it 'lists expected errors' do
        expect(endpoint.last_harvest.errors).to contain_exactly('Problem extracting xml ead links from endpoint')
      end
    end

    context 'when harvest partially complete' do
      let(:endpoint) do
        build(:endpoint, :webpage_harvest, :partial_harvest)
      end

      it 'returned status is partial' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::PARTIAL
        expect(endpoint.last_harvest.partial?).to be true
      end

      it 'lists expected problem files' do
        expect(
          endpoint.last_harvest.problem_files
        ).to contain_exactly(
          { 'id' => 'test-failed-id', 'status' => 'failed', 'errors' => ['Problem downloading file'] }
        )
      end
    end

    context 'when files were removed during harvest' do
      let(:endpoint) do
        build(:endpoint, :webpage_harvest, :harvest_with_removals)
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

  describe '#aspace_instance' do
    let(:endpoint) { build(:endpoint, :aspace_harvest, aspace_instance: aspace_instance) }
    let(:aspace_instance) { create(:aspace_instance) }

    it 'has no validation errors' do
      expect(endpoint.valid?).to be true
      expect(endpoint.aspace_instance).to be_a ASpaceInstance
    end

    it 'is an optional relationship' do
      endpoint.aspace_instance = nil
      expect(endpoint.valid?).to be true
    end
  end
end
