# frozen_string_literal: true

FactoryBot.define do
  factory :featured_collection do
    sequence(:record_id) { |n| "TEST#{n}" }
  end
end
