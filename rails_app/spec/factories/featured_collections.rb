# frozen_string_literal: true

FactoryBot.define do
  factory :featured_collection do
    sequence(:record_id) { |n| "TEST#{n}" }
    title { Faker::Book.title }
    repository { Faker::Company.name }
  end
end
