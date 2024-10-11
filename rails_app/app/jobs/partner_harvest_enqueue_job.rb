# frozen_string_literal: true

# Job to update endpoints from csv and enqueue PartnerHarvestJob jobs for all Endpoints.
class PartnerHarvestEnqueueJob < ApplicationJob
  queue_as :default

  def perform
    Endpoint.order(updated_at: :asc).each do |endpoint|
      PartnerHarvestJob.perform_later endpoint
    end
  end
end
