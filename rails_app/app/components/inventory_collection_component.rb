# frozen_string_literal: true

# Renders all InventoryComponents
class InventoryCollectionComponent < ViewComponent::Base
  # @param entries [Array<Ead::Extraction::Inventory::Entry>]
  # @param [Boolean] requestable
  def initialize(entries:, requestable: false)
    @entries = entries
    @requestable = requestable
  end
end
