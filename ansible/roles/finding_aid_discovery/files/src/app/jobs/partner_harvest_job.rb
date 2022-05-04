# frozen_string_literal: true

# job to harvest from a single endpoint
class PartnerHarvestJob < ApplicationJob
  rescue_from ActiveJob::DeserializationError do |exception|
    # TODO: endpoint has been removed
  end

  queue_as :default

  # @param [Endpoint] endpoint
  def perform(endpoint)
    HarvestingService.new(endpoint).harvest
  end
end
