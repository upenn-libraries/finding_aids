# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Extraction::Inventory::EntryPresenter do
  include EadHelpers
  let(:entry_class) { Ead::Extraction::Inventory::Entry }

  describe '.date' do
    it 'returns the non-bulk date when only present' do
      entry = instance_double(entry_class, non_bulk_date: '1900', bulk_date: nil)
      expect(described_class.date(entry)).to eq('1900')
    end

    it 'returns the bulk date in parentheses when only present' do
      entry = instance_double(entry_class, non_bulk_date: nil, bulk_date: 'bulk 1950-1960')
      expect(described_class.date(entry)).to eq('(bulk 1950-1960)')
    end

    it 'joins non-bulk and bulk dates' do
      entry = instance_double(entry_class, non_bulk_date: '1900-1910', bulk_date: 'bulk 1905-1908')
      expect(described_class.date(entry)).to eq('1900-1910 (bulk 1905-1908)')
    end

    it 'returns nil when no dates exist' do
      entry = instance_double(entry_class, non_bulk_date: nil, bulk_date: nil)

      expect(described_class.date(entry)).to be_nil
    end
  end

  describe '.extent_integer' do
    it 'removes trailing .0 from whole numbers' do
      entry = instance_double(entry_class, extent: '2.0 linear feet')

      expect(described_class.extent_integer(entry)).to eq(' 2 linear feet.')
    end

    it 'preserves decimal values' do
      entry = instance_double(entry_class, extent: '2.5 linear feet')
      expect(described_class.extent_integer(entry)).to eq(' 2.5 linear feet.')
    end

    it 'returns an empty string when extent is missing' do
      entry = instance_double(entry_class, extent: nil)
      expect(described_class.extent_integer(entry)).to eq('')
    end
  end

  describe '.join_containers' do
    it 'joins container labels with commas' do
      entry = instance_double(entry_class, containers: ['Box 1', 'Folder 2'])
      expect(described_class.join_containers(entry)).to eq('Box 1, Folder 2')
    end

    it 'returns an empty string when there are no containers' do
      entry = instance_double(entry_class, containers: [])
      expect(described_class.join_containers(entry)).to eq('')
    end
  end

  describe '.title' do
    it 'combines all fields in the expected format' do
      title = described_class.title(unitid: 'MS 123', origination: 'John Doe', title: 'Letters',
                                    date: '1900-1910', extent: ' 2 boxes.')
      expect(title).to eq('MS 123. John Doe. Letters, 1900-1910 2 boxes.')
    end

    it 'omits blank values' do
      expect(described_class.title(title: 'Letters')).to eq('Letters')
    end

    it 'returns the default title when everything is blank' do
      expect(described_class.title(title: nil)).to eq('(No Title)')
    end

    it 'returns a SafeBuffer' do
      expect(described_class.title(title: 'Letters')).to be_a(ActiveSupport::SafeBuffer)
    end
  end

  describe '.heading' do
    it 'builds a full heading from the entry' do
      entry = instance_double(
        entry_class,
        title_html: 'Correspondence',
        origination: 'Jane Smith',
        non_bulk_date: '1900',
        bulk_date: nil,
        extent: '3.0 folders'
      )

      expect(described_class.heading(entry)).to eq('Jane Smith. Correspondence, 1900 3 folders.')
    end
  end

  describe '.condensed_heading' do
    it 'omits date and extent' do
      entry = instance_double(entry_class, title_html: 'Correspondence', origination: 'Jane Smith')
      expect(described_class.condensed_heading(entry)).to eq('Jane Smith. Correspondence')
    end
  end
end
