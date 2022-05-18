# frozen_string_literal: true

require 'rails_helper'

describe AeonService do
  include AeonResponseMocks

  context 'with a successful request' do
    context 'with a penn affiliates' do
      let(:base_url) { AeonService::PENN_AUTH_URL }
      let(:request_params) do
        { 'SpecialRequest' => '',
          'Notes' => '',
          'auth' => '1',
          'UserReview' => '',
          'AeonForm' => '',
          'WebRequestForm' => '',
          'SubmitButton' => 'Submit',
          'Request' => '0',
          'ItemTitle_0' => '',
          'CallNumber_0' => '',
          'Site_0' => 'KISLAK',
          'SubLocation_0' => 'Manuscripts',
          'Location_0' => 'scmss',
          'ItemVolume_0' => '',
          'ItemIssue_0' => '' }
      end
      let(:aeon_request) do
        aeon_request = instance_double('AeonRequest')
        allow(aeon_request).to receive(:to_h).and_return request_params
        aeon_request
      end

      before do
        successful_single_request_penn body_hash: request_params.to_h
      end

      it 'works' do
        response = described_class.submit request: aeon_request, auth_type: :penn
        expect(response.success?).to be true
        expect(response.txnumber).to eq '12345'
      end
    end
  end
end
