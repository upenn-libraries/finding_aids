# frozen_string_literal: true

require 'rails_helper'

describe BaseExtractor do
  let(:endpoint) { build(:endpoint) }

  describe '.initialize' do
    it 'requires an Endpoint' do
      expect {
        described_class.new endpoint: 'Not an Endpoint'
      }.to raise_error StandardError
    end

    it 'sets #endpoint' do
      extractor = described_class.new endpoint: endpoint
      expect(extractor.endpoint).to be endpoint
    end
  end
end
