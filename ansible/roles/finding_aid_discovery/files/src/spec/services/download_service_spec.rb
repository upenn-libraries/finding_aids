# frozen_string_literal: true

require 'rails_helper'

describe DownloadService do
  describe '.fetch' do
    let(:url) { 'https://www.example.com' }

    it 'sets appropriate headers' do
      stub = stub_request(:get, url).with(headers: { 'User-Agent' => 'PACSCL Discovery harvester' })
      described_class.fetch(url)
      expect(stub).to have_been_made.once
    end
  end
end
