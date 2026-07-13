# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::Inventory::DigitalObject do
  describe '.web_url?' do
    it 'is true for an http(s) href' do
      expect(described_class.web_url?('https://example.com/thing')).to be true
    end

    it 'is false for a non-http href' do
      expect(described_class.web_url?('ftp://example.com/thing')).to be false
    end

    it 'handles a nil parameter' do
      expect { described_class.web_url?(nil) }.not_to raise_error
      expect(described_class.web_url?(nil)).to be false
    end
  end

  describe '#initialize' do
    it 'defaults title to the generic online resource label when nil' do
      dao = described_class.new(href: 'https://example.com', role: nil, title: nil)

      expect(dao.title).to eq('Online Resource')
    end

    it 'preserves a given title' do
      dao = described_class.new(href: 'https://example.com', role: nil, title: 'Finding Aid Scan')

      expect(dao.title).to eq('Finding Aid Scan')
    end
  end

  describe '#iiif?' do
    it 'is true when role matches the IIIF presentation API namespace' do
      dao = described_class.new(
        href: 'https://example.com/manifest.json',
        role: 'https://iiif.io/api/presentation/2.1/',
        title: nil
      )

      expect(dao.iiif?).to be true
    end

    it 'is false for any other role' do
      dao = described_class.new(href: 'https://example.com/thing.pdf', role: 'download', title: nil)

      expect(dao.iiif?).to be false
    end

    it 'is false when role is nil' do
      dao = described_class.new(href: 'https://example.com/thing.pdf', role: nil, title: nil)

      expect(dao.iiif?).to be false
    end
  end
end
