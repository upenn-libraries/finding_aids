# frozen_string_literal: true

# Turbo frame containing inventory collection with a turbo stream to update the table of contents
class InventoryTurboComponent < ViewComponent::Base
  include Turbo::StreamsHelper

  # @param entries [Array<Ead::Extraction::Inventory::Entry>]
  # @param document [SolrDocument]
  # @param presenter [Catalog::ShowDocumentPresenter]
  def initialize(entries:, document:, presenter:)
    @entries = entries
    @document = document
    @presenter = presenter
  end
end
