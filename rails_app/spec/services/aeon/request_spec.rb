# frozen_string_literal: true

require 'rails_helper'

describe Aeon::Request do
  let(:request) { described_class.new(params) }
  let(:params) { ActionController::Parameters.new(parameters) }
  let(:repository) { Settings.aeon.locations.first[:label] }
  let(:parameters) { {} }

  describe '.allowed?' do
    context 'with a supported location' do
      it 'returns true' do
        expect(described_class.allowed?(repository_name: repository)).to be true
      end
    end

    context 'with an unsupported location' do
      let(:repository) { "Bob's VHS Archive" }

      it 'returns false' do
        expect(described_class.allowed?(repository_name: repository)).to be false
      end
    end
  end

  describe '.new' do
    context 'with an unsupported location' do
      let(:parameters) { { repository: "Bob's VHS Archive" } }

      it 'raises an exception' do
        expect { request }.to raise_error(described_class::InvalidRequestError)
      end
    end

    context 'with a supported location' do
      let(:parameters) { { repository: repository } }

      it 'does not raise an exception' do
        expect { request }.not_to raise_error
      end
    end
  end

  describe '#items' do
    let(:parameters) do
      { call_num: 'test-call-num',
        repository: repository,
        title: 'Some old thing',
        request_type: 'Loan',
        special_request: 'I need this NOW!',
        notes: 'Thanks',
        retrieval_date: '2025-12-25',
        save_for_later: true,
        return_url: 'http://www.findingaids.com/record1',
        item: ['Month January: Page 6', 'Month December: Plate 40'],
        item_barcode: %w[111111111 222222222] }
    end

    let(:expected_item_metadata) do
      { 'CallNumber': 'test-call-num',
        'ItemTitle': 'Some old thing',
        'ItemVolume': 'Month January [111111111]',
        'ItemIssue': 'Page 6',
        'Request': 1 }
    end

    it 'has an array of Items' do
      expect(request.items.length).to eq 2
    end

    it 'has Items with proper hash representation' do
      expect(request.items.first.to_h).to include(expected_item_metadata)
    end
  end

  describe '#fulfillment_fields' do
    let(:parameters) { { repository: repository, request_type: request_type, retrieval_date: '2026-12-25' } }

    context 'with an in-person access request' do
      let(:request_type) { described_class::VISIT_REQUEST }

      it 'includes a scheduled date field' do
        expect(request.fulfillment_fields).to eq(
          { 'RequestType': request_type, 'ScheduledDate': '12/25/2026' }
        )
      end
    end

    context 'with a scan (reprographic) request' do
      let(:request_type) { described_class::SCAN_REQUEST }

      it 'includes only the request type field' do
        expect(request.fulfillment_fields).to eq({ 'RequestType': request_type })
      end
    end
  end
end
