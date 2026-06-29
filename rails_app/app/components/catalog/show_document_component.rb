# frozen_string_literal: true

module Catalog
  # Override Blacklight 9.0 component to customize layout
  class ShowDocumentComponent < Blacklight::DocumentComponent
    # @return [ActiveSupport::SafeBuffer]
    def repository
      render_single_value :repository_ssi
    end

    # @return [ActiveSupport::SafeBuffer]
    def abstract
      render_single_value :abstract_scope_contents_tsi
    end

    # @return [Enumerator<Blacklight::FieldPresenter>]
    def collection_overview
      presenter.field_presenters_by_group(:collection_overview)
    end

    # @return [Enumerator<Blacklight::FieldPresenter>]
    def contact
      presenter.field_presenters_by_group(:contact)
    end

    private

    # @return [ActiveSupport::SafeBuffer]
    def render_single_value(field)
      field_config = presenter.configuration.show_fields.slice(field)
      presenter.field_presenters(field_config) { |presenter| return presenter.render.first }
    end
  end
end
