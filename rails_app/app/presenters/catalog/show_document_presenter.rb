# frozen_string_literal: true

module Catalog
  # Custom DocumentPresenter copied from Blacklight 9.0.0 to facilitate rendering configured metadata fields across
  # show page
  class ShowDocumentPresenter < Blacklight::DocumentPresenter
    # @param group [Symbol]
    # [Enumerator<Blacklight::FieldPresenter>]
    def field_presenters_by_group(group)
      f = configuration[:show_fields].select { |_, field_config| field_config.group == group }
      field_presenters(f)
    end
  end
end
