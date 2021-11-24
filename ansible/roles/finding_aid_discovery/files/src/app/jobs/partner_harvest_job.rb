class PartnerHarvestJob < ApplicationJob
  def perform(partner)
    Harvester.run(partenr)
  end
end
