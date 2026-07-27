# frozen_string_literal: true

# Inventory controller used to power turboframes that make calls to lazy load additional information.
class InventoryController < ApplicationController
  include Blacklight::Searchable

  before_action :load_document # Loading document for all actions to ensure the document is present in our instance.

  # GET /inventory/:id/details
  def details
    respond_to do |format|
      format.html { render(InventoryTurboComponent.new(entries: entries, document: @document, presenter: presenter)) }
    end
  end

  private

  # @return [Catalog::ShowDocumentPresenter]
  def presenter
    Catalog::ShowDocumentPresenter.new(@document, view_context, blacklight_config)
  end

  # @return [SolrDocument]
  def load_document
    @document = search_service.fetch(params[:id])
  end

  # @return [Array<Ead::Extraction::Inventory::Entry>]
  def entries
    @entries ||= Ead::Extraction::Inventory::Entry.build_entries(@document.parsed_ead.dsc)
  end

  # @return [Blacklight::Configuration]
  def blacklight_config
    CatalogController.blacklight_config
  end
end
