# frozen_string_literal: true

require 'rails_helper'

describe HarvestingService do
  let(:endpoint) { create(:endpoint, :webpage_harvest) }

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
        stub_request(:get, endpoint.webpage_url).to_return(status: [200, ''])
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'does not send an email to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 0
      end
    end

    context 'when endpoint url returns a 404 error' do
      before do
        stub_request(:get, endpoint.webpage_url).to_return(status: 404)
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('the server responded with status 404')
      end

      it 'sends failure notification' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.from).to match_array('no-reply@library.upenn.edu')
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} failed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('the server responded with status 404')
      end

      it 'sends failure notification to endpoint tech contacts' do
        expect(ActionMailer::Base.deliveries.last.to).to match_array(endpoint.tech_contacts)
      end

      it 'CCs failure notification to local contact' do
        expect(ActionMailer::Base.deliveries.last.cc).to include HarvestNotificationMailer::FRIENDLY_PENN_PACSCL_CONTACT
      end
    end

    context 'when endpoint url returns a 500 error' do
      before do
        stub_request(:get, endpoint.webpage_url).to_return(status: 500)
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves error information to Endpoint' do
        expect(endpoint.last_harvest.errors.first).to include('the server responded with status 500')
      end
    end

    context 'when EAD cannot not be retrieved because of a HTTP error' do
      let(:url) { 'https://www.test.com/not_here.xml' }
      let(:xml_file) { WebpageExtractor::XMLFile.new(url: url) }
      let(:expected_file_error_hash) do
        [{
          'id' => 'not_here.xml',
          'status' => 'failed',
          'errors' => ['Problem downloading file: the server responded with status 404']
        }]
      end

      before do
        allow_any_instance_of(WebpageExtractor).to receive(:files).and_return([xml_file])
        stub_request(:get, endpoint.webpage_url).to_return(status: 200)
        stub_request(:get, url).to_return(status: 404)
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      it 'saves file error information to endpoint' do
        expect(endpoint.last_harvest.files).to match(expected_file_error_hash)
      end

      it 'sends partial harvest notification to tech contacts' do
        expect(ActionMailer::Base.deliveries.count).to be 1
        expect(ActionMailer::Base.deliveries.last.to).to match_array(endpoint.tech_contacts)
        expect(ActionMailer::Base.deliveries.last.cc).to(
          match_array(HarvestNotificationMailer::FRIENDLY_PENN_PACSCL_CONTACT)
        )
      end

      it 'sends partial harvest notification with appropriate subject and content' do
        expect(ActionMailer::Base.deliveries.last.subject).to eq "Harvest of #{endpoint.slug} partially completed"
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('Last Harvest Partially Completed')
        expect(ActionMailer::Base.deliveries.last.body.to_s).to match('the server responded with status 404')
      end
    end

    context 'when EAD 3 format is detected in a file' do
      before do
        stub_extractor = instance_double BaseExtractor, files: files
        allow(endpoint).to receive(:extractor).and_return stub_extractor
        described_class.new(endpoint).harvest
        endpoint.reload
      end

      let(:files) do
        [instance_double(BaseExtractor::BaseEadSource,
                         xml: file_fixture('ead/ead3_aspace_export.xml').read,
                         source_id: '123')]
      end

      it 'save error message making it clear that EAD 3 is unsupported' do
        file_errors = endpoint.last_harvest.files.pluck('errors').flatten
        expect(file_errors.join(' ')).to include 'EAD3 spec not supported'
      end
    end
  end
end
