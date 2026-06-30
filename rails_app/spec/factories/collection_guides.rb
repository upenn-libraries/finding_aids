# frozen_string_literal: true

FactoryBot.define do
  factory :collection_guide do
    title { 'Test Collection Guide' }
    repository { 'Test Repository' }
    active { true }
  end
end
