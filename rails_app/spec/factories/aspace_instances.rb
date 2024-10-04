# frozen_string_literal: true

FactoryBot.define do
  factory :aspace_instance do
    slug { Faker::Internet.unique.slug(glue: '_') }
    base_url { Faker::Internet.url }
  end
end
