require 'rails_helper'

describe IndexExtractor do
  let(:endpoint) { FactoryBot.build :endpoint, :index_harvest }
  let(:html) { file_fixture('xml_listing.html').read }
  let(:extractor) { described_class.new(endpoint) }

  context 'enumerability' do
    before do
      stub_request(:get, endpoint.url).to_return(body: html)
    end

    it 'responds to enumerable methods' do
      expect(extractor).to respond_to :each, :each_slice, :map, :first
    end

    it 'yields an EndpointXmlFile' do
      expect(extractor.first).to be_an_instance_of EndpointXmlFile
    end
  end

  context 'error handling (or not)' do
    before do
      stub_request(:get, endpoint.url).to_return(status: ['404', 'Not Found'])
    end

    it 'raises an OpenURI::HTTPError' do
      expect { extractor }.to raise_error OpenURI::HTTPError
    end
  end
end
