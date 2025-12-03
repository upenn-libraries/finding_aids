# frozen_string_literal: true

require 'rails_helper'

describe DownloadService do
  let(:url) { 'https://www.example.com' }

  describe '.fetch' do
    it 'sets appropriate headers' do
      stub = stub_request(:get, url).with(headers: described_class::HEADERS)
      described_class.fetch(url)
      expect(stub).to have_been_made.once
    end

    context 'when request is unsuccessful' do
      it 'raises error' do
        stub_request(:get, url).with(headers: described_class::HEADERS)
                               .to_return(status: 500)
        expect { described_class.fetch(url) }.to raise_error(described_class::DownloadServiceError)
      end
    end
  end
end
