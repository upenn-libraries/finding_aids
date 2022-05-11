# frozen_string_literal: true

require 'rails_helper'

describe AeonRequest do
  let(:request) { described_class.new(params) }

  describe '#submit' do
    context 'with some sample params' do
      let(:params) do
        ActionController::Parameters.new(
          { call_num: 'test-call-num',
            repository: 'a-requestable-repo',
            title: 'some-old-thing',
            special_request: 'I need this NOW!!',
            notes: 'Thanks',
            retrieval_date: '',
            save_for_later: true,
            item0: 'Month January, Page 6',
            item1: 'Month December, Plate 40' }
        )
      end

      it 'works' do
        expect(request).to be_a described_class
      end

      it 'has an array of Items' do
        expect(request.items).to be_a Array
        expect(request.items.length).to eq 2
        expect(request.items.first).to be_an AeonRequest::Item
      end
    end
  end

end
