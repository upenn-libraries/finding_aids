# frozen_string_literal: true

# Renders all InventoryComponents
class InventoryCollectionComponent < ViewComponent::Base
  # @param entries [Array<Ead::Extraction::Inventory::Entry>]
  # @param requestable [Boolean]
  def initialize(entries:, requestable: false)
    @entries = entries
    @requestable = requestable
  end
end
