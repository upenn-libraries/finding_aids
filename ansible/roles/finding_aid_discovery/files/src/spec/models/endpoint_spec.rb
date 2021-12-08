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
  context 'storage of harvest results' do
    context 'success' do
      let(:successful_harvest) {
        FactoryBot.build(:endpoint, :index_harvest, :successful_harvest)
      }
      it 'is marked as successful' do
        expect(successful_harvest.last_harvest_failed?).to be false
        expect(successful_harvest.last_harvest_successful?).to be true
      end
    end
    context 'failed' do
      let(:failed_harvest) {
        FactoryBot.build(:endpoint, :index_harvest, :failed_harvest)
      }
      it 'is marked as failed' do
        expect(failed_harvest.last_harvest_successful?).to be false
        expect(failed_harvest.last_harvest_failed?).to be true
      end
    end
  end
end
