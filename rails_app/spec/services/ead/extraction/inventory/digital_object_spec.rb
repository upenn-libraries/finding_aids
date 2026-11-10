# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::Inventory::DigitalObject do
  let(:dao) { described_class.new(**attributes) }

  describe '#initialize' do
    context 'when title is nil' do
      let(:attributes) { { href: 'https://example.com', role: nil, title: nil } }

      it 'defaults to the generic online resource label' do
        expect(dao.title).to eq(Ead::Extraction::Inventory::DigitalObject::ONLINE_RESOURCE)
      end
    end

    context 'when a title is given' do
      let(:attributes) { { href: 'https://example.com', role: nil, title: 'Finding Aid Scan' } }

      it 'preserves a given title' do
        expect(dao.title).to eq(attributes[:title])
      end
    end
  end

  describe '#display?' do
    context 'with a link with an IIIF role' do
      let(:attributes) do
        { href: 'https://example.com', role: 'https://iiif.io/api/presentation/2.1/',
          title: 'IIIF Manifest' }
      end

      it 'returns false' do
        expect(dao.display?).to be false
      end
    end

    context 'with no role and an http link' do
      let(:attributes) { { href: 'https://example.com', role: nil, title: 'Web Link' } }

      it 'returns true' do
        expect(dao.display?).to be true
      end
    end

    context 'with a non-http link' do
      let(:attributes) { { href: 'ftp://example.com/file.zip', role: nil, title: 'FTP Link' } }

      it 'returns false' do
        expect(dao.display?).to be false
      end
    end
  end
end
