# frozen_string_literal: true

require 'rails_helper'

describe AeonRequest do
  let(:request) { described_class.new(params) }

  context 'with some sample params' do
    let(:params) do
      ActionController::Parameters.new(
        { call_num: 'test-call-num',
          repository: 'University of Pennsylvania: Kislak Center for Special Collections, Rare Books and Manuscripts',
          title: 'Some old thing',
          special_request: 'I need this NOW!',
          notes: 'Thanks',
          retrieval_date: '2025-12-25',
          save_for_later: true,
          auth_type: 'penn',
          item: ['Month January: Page 6', 'Month December: Plate 40'],
          item_barcode: %w[111111111 222222222] }
      )
    end

    describe '#items' do
      let(:expected_item_hash) do
        { 'CallNumber_0' => 'test-call-num',
          'ItemTitle_0' => 'Some old thing',
          'ItemAuthor_0' => '',
          'Site_0' => 'KISLAK',
          'SubLocation_0' => 'Manuscripts',
          'Location_0' => 'scmss',
          'ItemVolume_0' => 'Month January [111111111]',
          'ItemIssue_0' => 'Page 6',
          'Request_0' => 0 }
      end

      it 'has an array of Items' do
        expect(request.items.length).to eq 2
        expect(request.items.first).to be_an described_class::Item
      end

      it 'has Items with proper hash representation' do
        expect(request.items.first).to respond_to :to_h
        expect(request.items.first.to_h).to eq(expected_item_hash)
      end
    end

    describe '#to_h' do
      it 'has a hash representation with proper note fields' do
        expect(request.to_h).to include(
          { 'SpecialRequest' => 'I need this NOW!',
            'Notes' => 'Thanks' }
        )
      end

      it 'has a hash representation with proper fulfillment fields' do
        expect(request.to_h).to include(
          { 'UserReview' => 'No',
            'ScheduledDate' => '12/25/2025' }
        )
      end

      it 'has a hash representation with proper auth field' do
        expect(request.to_h).to include({ 'auth' => '1' })
      end
    end

    describe '#prepare' do
      it 'has expected url value' do
        expect(request.prepared).to include({ url: described_class::AUTH_INFO_MAP[:penn][:url] })
      end

      it 'has expected request representation as a hash' do
        expect(request.prepared[:body]).to be_a Hash
      end
    end
  end
end
