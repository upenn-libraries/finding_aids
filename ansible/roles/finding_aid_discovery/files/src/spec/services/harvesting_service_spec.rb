require 'rails_helper'

describe HarvestingService do
  let(:endpoint) { FactoryBot.create :endpoint, :index_harvest }

  describe '#process_deletes' do
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

  describe '#harvest' do
    context 'when endpoint url returns a 404 error' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [404, 'Not Found'])
        described_class.new(endpoint).harvest
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('404 Not Found')
      end

      it 'sends failure notification to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.to).to match_array('tech@test.org')
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} failed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('404 Not Found')
      end
    end

    context 'when endpoint url return a 500 error' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [500, 'Internal Server Error'])
        described_class.new(endpoint).harvest
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('500 Internal Server Error')
      end
    end

    context 'when EAD cannot not be retrieved because of a HTTP error' do
      let(:url) { 'https://www.test.com/not_here.xml' }
      let(:xml_file) { IndexExtractor::XMLFile.new(url) }

      before do
        allow_any_instance_of(IndexExtractor).to receive(:files).and_return([xml_file])
        stub_request(:get, endpoint.url).to_return(status: [200])
        stub_request(:get, url).to_return(status: [404, 'Not Found'])
        described_class.new(endpoint).harvest
      end

      it 'saves file error information to endpoint' do
        file_error_hash = endpoint.last_harvest_results['files'].first
        expect(file_error_hash.keys).to include 'filename', 'status', 'errors'
        expect(file_error_hash['status']).to eq 'failed'
        expect(file_error_hash['errors'].first).to include '404 Not Found'
      end

      it 'sends partial harvest notification to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.to).to match_array('tech@test.org')
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} partially completed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('Last Harvest Partially Completed')
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('404 Not Found')
      end
    end
  end
end
