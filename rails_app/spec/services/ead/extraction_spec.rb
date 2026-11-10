# frozen_string_literal: true

describe Ead::Extraction do
  describe Ead::Extraction::Definition do
    it 'stores the term and translation' do
      definition = described_class.new('bioghist', 'Some history')

      expect(definition.term).to eq('bioghist')
      expect(definition.translation).to eq('Some history')
    end
  end
end
