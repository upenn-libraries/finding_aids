FactoryBot.define do
  factory :endpoint do
    slug { Faker::Internet.unique.slug }
    public_contacts { ['public@test.org'] }
    tech_contacts { ['tech@test.org'] }

    trait :index_harvest do
      harvest_config { {
        type: 'index', url: 'https://www.test.com/pacscl'
      } }
    end

    trait :failed_harvest do
      last_harvest_results { {
        date: DateTime.current,
        errors: ['Problem extracting xml ead links from endpoint'],
        files: []
      } }
    end

    trait :partial_harvest do # problems with individual EADs
      last_harvest_results { {
        date: DateTime.current,
        errors: [],
        files: [
          { filename: '', id: 'test-ok-id', status: :ok },
          { filename: '', status: :failed, errors: ['Problem downloading XML file'] }
        ]
      } }
    end

    trait :complete_harvest do
      last_harvest_results { {
        date: DateTime.current,
        errors: [],
        files: [
          { filename: '', status: :ok, id: 'test-ok-id' },
        ]
      } }
    end

    trait :harvest_with_removals do
      last_harvest_results { {
        date: DateTime.current,
        errors: [],
        files: [
          { filename: '', id: 'test-ok-id', status: :ok },
          { id: 'removed-record-1', status: :removed },
          { id: 'removed-record-2', status: :removed }
        ]
      } }
    end
  end
end
