# frozen_string_literal: true

require 'rails_helper'

describe ASpaceInstance do
  let(:aspace_instance) { build(:aspace_instance) }

  it 'has no validation errors' do
    expect(aspace_instance.valid?).to be true
  end

  describe '#slug' do
    it 'must be present' do
      aspace_instance.slug = nil
      expect(aspace_instance.valid?).to be false
      expect(aspace_instance.errors[:slug]).to include('can\'t be blank')
    end

    it 'must be unique' do
      new_aspace_instance = create(:aspace_instance)
      aspace_instance.slug = new_aspace_instance.slug
      expect(aspace_instance.valid?).to be false
      expect(aspace_instance.errors[:slug]).to include('has already been taken')
    end

    it 'must only contain lowercase letters and underscores' do
      aspace_instance.slug = 'TEST_SLUG'
      expect(aspace_instance.valid?).to be false
      expect(aspace_instance.errors[:slug]).to include('is invalid')
    end

    it 'must be less than 20 characters' do
      aspace_instance.slug = 'university_of_pennsylvania'
      expect(aspace_instance.valid?).to be false
      expect(aspace_instance.errors[:slug]).to include('is too long (maximum is 20 characters)')
    end
  end

  describe '#base_url' do
    it 'must be present' do
      aspace_instance.base_url = nil
      expect(aspace_instance.valid?).to be false
      expect(aspace_instance.errors[:base_url]).to include('can\'t be blank')
    end
  end

  describe '#endpoints' do
    let(:endpoints) { create_list(:endpoint, 2, :aspace_harvest, aspace_instance: nil) }

    before do
      aspace_instance.endpoints = endpoints
      aspace_instance.save
    end

    it 'can have many endpoints' do
      expect(aspace_instance.endpoints).to all be_an_instance_of(Endpoint)
    end

    it 'raises an exception on delete if there are still related endpoints' do
      expect { aspace_instance.destroy }.to raise_error ActiveRecord::DeleteRestrictionError
    end
  end
end
