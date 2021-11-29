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
        status: Endpoint::FAILURE_STATUS
      } }
    end

    trait :successful_harvest do
      last_harvest_results { {
        status: Endpoint::SUCCESS_STATUS
      } }
    end
  end
end
