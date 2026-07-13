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
    it 'matches phone numbers with parentheses' do
      phone = '(215) 555-1234'
      expect(phone).to match(described_class::CONTACT_PATTERN)
    end

    it 'matches phone numbers with dots' do
      phone = '215.555.1234'
      expect(phone).to match(described_class::CONTACT_PATTERN)
    end

    it 'matches phone numbers with dashes' do
      phone = '215-555-1234'
      expect(phone).to match(described_class::CONTACT_PATTERN)
    end

    it 'matches email indicators' do
      email = 'info@example.org'
      expect(email).to match(described_class::CONTACT_PATTERN)
    end

    it 'matches URL indicators' do
      url_text = 'Visit us at URL:'
      expect(url_text).to match(described_class::CONTACT_PATTERN)
    end

    it 'matches raw URLs' do
      url = 'http://example.org'
      expect(url).to match(described_class::CONTACT_PATTERN)
    end

    it 'does not match plain street addresses' do
      address = '123 Main St'
      expect(address).not_to match(described_class::CONTACT_PATTERN)
    end

    it 'BUILDING_NAME_PATTERN matches non-numeric-start lines' do
      building = 'Falvey Library'
      expect(building).to match(described_class::BUILDING_NAME_PATTERN)
    end

    it 'BUILDING_NAME_PATTERN rejects numeric-start lines' do
      address = '800 E Lancaster Ave'
      expect(address).not_to match(described_class::BUILDING_NAME_PATTERN)
    end
  end
end
