# frozen_string_literal: true

# job enqueue PartnerHarvestJob jobs for some of the least-recently-updated Endpoints
class PartnerHarvestEnqueueJob < ApplicationJob
  queue_as :default

  # enqueue jobs
  def perform
    Endpoint.order(updated_at: :asc).each do |endpoint|
      PartnerHarvestJob.perform_later endpoint
    end
  end
end
