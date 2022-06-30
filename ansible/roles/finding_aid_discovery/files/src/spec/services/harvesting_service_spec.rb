# frozen_string_literal: true

require 'rails_helper'

describe HarvestingService do
  let(:endpoint) { create :endpoint, :index_harvest }

  describe '#process_deletes' do
    let(:solr_service) { instance_double SolrService }
    let(:harvesting_service) { described_class.new(endpoint, solr_service) }

    before do
      allow(solr_service).to receive(:find_ids_by_endpoint).with(endpoint.slug).and_return([1, 3])
      allow(solr_service).to receive(:delete_by_ids)
      allow(harvesting_service).to receive(:document_ids).and_return([1, 2])
    end

    it 'sends correct ids for records to remove to the solr service' do
      expect(solr_service).to receive(:delete_by_ids).with([3])
      harvesting_service.process_removals
    end
  end

  describe '#harvest' do
    context 'when everything goes to plan' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [200, ''])
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'does not send an email to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 0
      end
    end

    context 'when endpoint url returns a 404 error' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [404, 'Not Found'])
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('404 Not Found')
      end

      it 'sends failure notification to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.to).to match_array(endpoint.tech_contacts)
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} failed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('404 Not Found')
      end
    end

    context 'when endpoint url return a 500 error' do
      before do
        stub_request(:get, endpoint.url).to_return(status: [500, 'Internal Server Error'])
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('500 Internal Server Error')
      end
    end

    context 'when EAD cannot not be retrieved because of a HTTP error' do
      let(:url) { 'https://www.test.com/not_here.xml' }
      let(:xml_file) { IndexExtractor::XMLFile.new(url:) }
      let(:expected_file_error_hash) do
        [{
          'id' => 'not_here',
          'status' => 'failed',
          'errors' => ['Problem downloading file: 404 Not Found']
        }]
      end

      before do
        allow_any_instance_of(IndexExtractor).to receive(:files).and_return([xml_file])
        stub_request(:get, endpoint.url).to_return(status: [200])
        stub_request(:get, url).to_return(status: [404, 'Not Found'])
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves file error information to endpoint' do
        expect(endpoint.last_harvest.files).to match(expected_file_error_hash)
      end

      it 'sends partial harvest notification to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.to).to match_array(endpoint.tech_contacts)
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} partially completed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('Last Harvest Partially Completed')
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('404 Not Found')
      end
    end
  end
end
