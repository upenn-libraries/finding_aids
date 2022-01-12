require 'rails_helper'

describe HarvestingService do
  let(:endpoint) { FactoryBot.create :endpoint, :index_harvest }
  context '#process_deletes' do
    let(:solr_service) do
      instance_double 'SolrService'
    end
    let(:harvesting_service) { described_class.new(endpoint, solr_service) }
    before do
      allow(solr_service).to receive(:find_ids_by_endpoint).with(endpoint).and_return([1, 3])
      allow(solr_service).to receive(:delete_by_ids)
    end
    it 'sends correct ids for records to remove to the solr service' do
      expect(solr_service).to receive(:delete_by_ids).with([3])
      harvesting_service.process_removals(harvested_doc_ids: [1, 2])
    end
  end
  context 'error handling' do
    context 'for an HTTP 404 error from extractor' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [404, 'Not Found'])
      end

      it 'saves error information to Endpoint' do
        described_class.new(endpoint).harvest
        expect(endpoint.last_harvest.errors.first).to include '404 Not Found'
      end
    end

    context 'for an HTTP 500 error from extractor' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [500, 'Internal Server Error'])
      end

      it 'saves error information to Endpoint' do
        described_class.new(endpoint).harvest
        expect(endpoint.last_harvest.errors.first).to include '500 Internal Server Error'
      end
    end

    context '#process' do
      context 'error handling' do
        context 'for an HTTP error from indexer' do
          let(:url) { 'https://www.test.com/not_here.xml' }
          let(:xml_file) { IndexExtractor::XMLFile.new(url) }

          before do
            allow_any_instance_of(IndexExtractor).to receive(:files).and_return([xml_file])
            stub_request(:get, endpoint.url).to_return(status: [200])
            stub_request(:get, url).to_return(status: [404, 'Not Found'])
          end

          it 'saves file error information to endpoint' do
            described_class.new(endpoint).harvest
            file_error_hash = endpoint.last_harvest.files.first
            expect(file_error_hash.keys).to include 'filename', 'status', 'errors'
            expect(file_error_hash['status']).to eq 'failed'
            expect(file_error_hash['errors'].first).to include '404 Not Found'
          end
        end
      end
    end
  end
end
