# frozen_string_literal: true

FactoryBot.define do
  factory :featured_collection do
    sequence(:title) { |n| "Test Collection #{n}" }
    repository { 'Test Repository' }
  end
end
