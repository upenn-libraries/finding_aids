# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::Inventory::Container do
  describe '#to_s' do
    it 'joins type and text with a single space, no stray whitespace' do
      container = described_class.new(type: 'Box', local_type: nil, text: 'JES.0001', label: nil)

      expect(container.to_s).to eq('Box JES.0001')
    end

    it 'is an empty string when both type and text are absent' do
      container = described_class.new(type: nil, local_type: nil, text: nil, label: nil)

      expect(container.to_s).to eq('')
    end
  end

  describe '#type' do
    it 'prefers type over local_type when both are present' do
      container = described_class.new(type: 'box', local_type: 'folder', text: '1', label: nil)

      expect(container.type).to eq('Box')
    end

    it 'falls back to local_type when type is absent' do
      container = described_class.new(type: nil, local_type: 'folder', text: '1', label: nil)

      expect(container.type).to eq('Folder')
    end

    it 'is nil when neither type nor local_type is present' do
      container = described_class.new(type: nil, local_type: nil, text: '1', label: nil)

      expect(container.type).to be_nil
    end
  end

  describe '#barcode' do
    it 'extracts a bracketed value from the label' do
      container = described_class.new(type: 'Box', local_type: nil, text: '1', label: 'Shelf note [B123456]')

      expect(container.barcode).to eq('B123456')
    end

    it 'is nil when the label has no bracketed value' do
      container = described_class.new(type: 'Box', local_type: nil, text: '1', label: 'Shelf note')

      expect(container.barcode).to be_nil
    end

    it 'is nil when the label is blank' do
      container = described_class.new(type: 'Box', local_type: nil, text: '1', label: nil)

      expect(container.barcode).to be_nil
    end
  end
end
