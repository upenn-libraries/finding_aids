# frozen_string_literal: true

# job enqueue PartnerHarvestJob jobs for some of the least-recently-updated Endpoints
class PartnerHarvestEnqueueJob < ApplicationJob
  queue_as :default

  def perform
    # get stalest endpoints
    num_endpoints = ENV.fetch('HARVESTS_TO_ENQUEUE', 10)
    endpoints = Endpoint.order(updated_at: :asc).limit(num_endpoints)

    # enqueue jobs
    endpoints.each do |endpoint|
      PartnerHarvestJob.perform_later endpoint
    end
  end
end
