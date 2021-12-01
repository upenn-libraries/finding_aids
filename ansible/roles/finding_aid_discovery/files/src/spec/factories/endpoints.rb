FactoryBot.define do
  factory :endpoint do
    slug { 'test' }
    public_contacts { ['public@test.org'] }
    tech_contacts { ['tech@test.org'] }

    trait :index_harvest do
      harvest_config { {
        type: 'index', url: 'https://www.test.com/pacscl'
      } }
    end

    trait :failed_harvest do
      last_harvest_results { {
        date: 'some date',
        errors: ['Problem extracting xml ead links from endpoint'],
        files: []
      } }
    end

    trait :harvest_with_file_problem do
      last_harvest_results { {
        date: 'some date',
        errors: [],
        files: [
          { filename: '', status: :ok, id: 'test-ok-id', errors: [] },
          { filename: '', status: :failed, id: 'test-failed-id', errors: ['Problem downloading XML file'] }
        ]
      } }
    end

    trait :successful_harvest do
      last_harvest_results { {
        date: 'some date',
        errors: [],
        files: [
          { filename: '', status: :ok, id: 'test-ok-id', errors: [] },
        ]
      } }
    end
  end
end
