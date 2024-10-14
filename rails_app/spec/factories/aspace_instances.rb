# frozen_string_literal: true

FactoryBot.define do
  factory :aspace_instance do
    slug { Faker::Internet.username(specifier: 5..15, separators: ['_']) }
    base_url { Faker::Internet.url }
  end
end
