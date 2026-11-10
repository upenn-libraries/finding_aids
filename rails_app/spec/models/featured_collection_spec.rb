# frozen_string_literal: true

require 'rails_helper'

describe FeaturedCollection do
  subject(:featured_collection) { create :featured_collection }

  describe '#record_id' do
    it 'must be present' do
      new_fc = build :featured_collection, record_id: nil
      expect(new_fc.valid?).to be false
      expect(new_fc.errors.messages[:record_id]).to include 'can\'t be blank'
    end

    it 'must be unique' do
      fc_record_id = featured_collection.record_id
      new_fc = build :featured_collection, record_id: fc_record_id
      expect(new_fc.valid?).to be false
      expect(new_fc.errors.messages[:record_id]).to include 'has already been taken'
    end
  end
end
