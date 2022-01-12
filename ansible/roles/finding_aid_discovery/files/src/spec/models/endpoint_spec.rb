require 'rails_helper'

describe Endpoint do
  context 'basic attributes' do
    let(:index_endpoint) do
      FactoryBot.build(:endpoint, :index_harvest)
    end
    it 'has no validation errors' do
      expect(index_endpoint.valid?).to be true
    end
    it 'has functioning JSON accessor methods' do
      expect(index_endpoint.url).to eq 'https://www.test.com/pacscl'
      expect(index_endpoint.type).to eq 'index'
    end
  end

  context 'validations' do
    context 'harvest configuration' do
      let(:bad_type_config_endpoint) {
        FactoryBot.build(:endpoint, harvest_config: { url: '', type: 'gopher' })
      }
      it 'has validation errors for url and type' do
        bad_type_config_endpoint.valid?
        expect(bad_type_config_endpoint.errors.attribute_names).to include :url, :type
        expect(bad_type_config_endpoint.errors.where(:type).first.type).to eq :inclusion
      end
    end
  end

  context '#harvest_results' do
    context 'when harvest has never been run' do
      let(:endpoint) do
        FactoryBot.build(:endpoint, :index_harvest)
      end

      it 'return status as nil' do
        expect(endpoint.last_harvest.status).to be nil
      end
    end

    context 'when harvest complete' do
      let(:endpoint) do
        FactoryBot.build(:endpoint, :index_harvest, :complete_harvest)
      end

      it 'returned status is "completed"' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::COMPLETE
        expect(endpoint.last_harvest.complete?).to be true
      end
    end

    context 'when harvest failed' do
      let(:endpoint) do
        FactoryBot.build(:endpoint, :index_harvest, :failed_harvest)
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
        FactoryBot.build(:endpoint, :index_harvest, :partial_harvest)
      end

      it 'returned status is partial' do
        expect(endpoint.last_harvest.status).to eql Endpoint::LastHarvest::PARTIAL
        expect(endpoint.last_harvest.partial?).to be true
      end

      it 'lists expected problem files' do
        expect(endpoint.last_harvest.problem_files).to match_array [{ 'filename' => '', 'status' => 'failed', 'errors' => ['Problem downloading XML file'] }]
      end
    end

    context 'when files were removed during harvest' do
      let(:endpoint) do
        FactoryBot.build(:endpoint, :index_harvest, :harvest_with_removals)
      end

      it 'removals returns true' do
        expect(endpoint.last_harvest.removals?).to be true
      end

      it 'list files that were removed' do
        expect(endpoint.last_harvest.removed_files).to match_array [{ 'id' => 'removed-record-1', 'status' => 'removed' }, { 'id' => 'removed-record-2', 'status' => 'removed' }]
      end
    end
  end
end
