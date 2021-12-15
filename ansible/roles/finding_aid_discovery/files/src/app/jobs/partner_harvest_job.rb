class PartnerHarvestJob < ApplicationJob
  def perform(endpoint)
    HarvestingService.new(endpoint)
                     .harvest
  end
end
