# frozen_string_literal: true

# Inventory controller used to power turboframes that make calls to lazy load additional information.
class InventoryController < ApplicationController
  include Blacklight::Searchable

  delegate :blacklight_config, to: CatalogController

  before_action :load_document # Loading document for all actions to ensure the document is present in our instance.

  # GET /inventory/:id/details
  def details
    respond_to do |format|
      format.html { render(InventoryTurboComponent.new(entries: entries, document: @document, presenter: presenter)) }
    end
  end

  private

  def presenter
    Catalog::ShowDocumentPresenter.new(@document, view_context, blacklight_config)
  end

  def load_document
    @document = search_service.fetch(params[:id])
  end

  def entries
    @entries ||= Ead::Extraction::Inventory::Entry.build_entries(@document.parsed_ead.dsc)
  end
end
