class PartnerHarvestJob < ApplicationJob
  def perform(endpoint)
    HarvestingService.new(endpoint)
                     .process
  end
end
