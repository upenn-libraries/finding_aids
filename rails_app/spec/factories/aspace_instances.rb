# frozen_string_literal: true

FactoryBot.define do
  factory :aspace_instance do
    slug { Faker::Internet.username(specifier: 5..15, separators: ['_']) }
    base_url { Faker::Internet.url }
  end

  trait :with_custom_throttle do
    throttle { 1.1 }
  end

  trait :with_endpoints do
    transient do
      endpoint_count { 2 }
    end

    endpoints do
      Array.new(endpoint_count) { |i| association(:endpoint, :aspace_harvest, aspace_repo_id: i + 1) }
    end
  end
end
