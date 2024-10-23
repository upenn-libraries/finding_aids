# frozen_string_literal: true

FactoryBot.define do
  factory :endpoint do
    slug { Faker::Internet.unique.slug(glue: '_') }
    public_contacts { ['public@test.org'] }
    tech_contacts { ['tech@test.org'] }

    trait :webpage_harvest do
      source_type { Endpoint::WEBPAGE_TYPE }
      webpage_url { 'https://www.test.com/pacscl' }
    end

    trait :aspace_harvest do
      source_type { Endpoint::ASPACE_TYPE }
      aspace_repo_id { '1' }

      association :aspace_instance
    end

    trait :failed_harvest do
      last_harvest_results do
        {
          date: DateTime.current,
          errors: ['Problem extracting xml ead links from endpoint'],
          files: []
        }
      end
    end

    trait :partial_harvest do # problems with individual EADs
      last_harvest_results do
        {
          date: DateTime.current,
          errors: [],
          files: [
            { id: 'test-ok-id', status: :ok },
            { id: 'test-failed-id', status: :failed, errors: ['Problem downloading file'] }
          ]
        }
      end
    end

    trait :complete_harvest do
      last_harvest_results do
        {
          date: DateTime.current,
          errors: [],
          files: [
            { filename: '', status: :ok, id: 'test-ok-id' }
          ]
        }
      end
    end

    trait :inactive_harvest do
      last_harvest_results do
        {
          date: DateTime.current,
          errors: [
            "Something went wrong during extraction: #{slug} is inactive." \
            'Please reactivate to harvest from this endpoint.'
          ],
          files: []
        }
      end
    end

    trait :harvest_with_removals do
      last_harvest_results do
        {
          date: DateTime.current,
          errors: [],
          files: [
            { id: 'test-ok-id', status: :ok },
            { id: 'removed-record-1', status: :removed },
            { id: 'removed-record-2', status: :removed }
          ]
        }
      end
    end
  end
end
