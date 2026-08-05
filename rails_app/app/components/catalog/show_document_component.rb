# frozen_string_literal: true

module Catalog
  # Override Blacklight 9.0 component to customize layout
  class ShowDocumentComponent < Blacklight::DocumentComponent
    include Turbo::FramesHelper

    # Stimulus controllers to connect to the document section
    # @return [String]
    def connected_controller_names
      controllers = if @document.requestable?
                      %w[guide-navigation request]
                    else
                      ['guide-navigation']
                    end

      controllers.join(' ')
    end

    # @return [ActiveSupport::SafeBuffer]
    def repository
      presenter.render_single_value(:repository_ssi)
    end

    # @return [ActiveSupport::SafeBuffer]
    def abstract
      presenter.render_single_value(:abstract_scope_contents_tsi)
    end

    # @return [Enumerator<Blacklight::FieldPresenter>]
    def collection_overview
      presenter.field_presenters_by_group(:collection_overview)
    end

    # @return [Enumerator<Blacklight::FieldPresenter>]
    def contact
      presenter.field_presenters_by_group(:contact)
    end

    # @return [Array<Ead::Extraction::Inventory::Entry>]
    def inventory_entries
      @inventory_entries ||= Ead::Extraction::Inventory::Entry.build_entries(@document.parsed_ead.dsc)
    end
  end
end
