# frozen_string_literal: true

require 'rails_helper'

describe Geocoding::AddressCleaner do
  describe '.clean' do
    it 'strips parenthetical notes' do
      expect(described_class.clean('123 Main St (2nd floor), Philadelphia, PA'))
        .to eq('123 Main St, Philadelphia, PA')
    end

    it 'collapses double commas' do
      expect(described_class.clean('123 Main St,, Philadelphia, PA'))
        .to eq('123 Main St, Philadelphia, PA')
    end

    it 'strips trailing whitespace' do
      expect(described_class.clean('  123 Main St, Philadelphia, PA  '))
        .to eq('123 Main St, Philadelphia, PA')
    end

    it 'handles addresses without parentheticals' do
      expect(described_class.clean('370 Lancaster Ave, Haverford, PA 19041'))
        .to eq('370 Lancaster Ave, Haverford, PA 19041')
    end
  end

  describe 'constants' do
    it 'matches phone numbers' do
      expect('(215) 555-1234').to match(described_class::CONTACT_PATTERN)
      expect('215.555.1234').to match(described_class::CONTACT_PATTERN)
      expect('215-555-1234').to match(described_class::CONTACT_PATTERN)
    end

    it 'matches email indicators' do
      expect('info@example.org').to match(described_class::CONTACT_PATTERN)
    end

    it 'matches URL indicators' do
      expect('Visit us at URL:').to match(described_class::CONTACT_PATTERN)
      expect('http://example.org').to match(described_class::CONTACT_PATTERN)
    end

    it 'does not match plain street addresses' do
      expect('123 Main St').not_to match(described_class::CONTACT_PATTERN)
    end

    it 'BUILDING_NAME_PATTERN matches non-numeric-start lines' do
      expect('Falvey Library').to match(described_class::BUILDING_NAME_PATTERN)
    end

    it 'BUILDING_NAME_PATTERN rejects numeric-start lines' do
      expect('800 E Lancaster Ave').not_to match(described_class::BUILDING_NAME_PATTERN)
    end
  end
end
