# frozen_string_literal: true

module Catalog
  # Overrides Blacklight::FieldPresenter based on Blacklight 9.0.0 to ensure fields are not joined and
  # html links are not included in json responses.
  class FieldPresenter < Blacklight::FieldPresenter
    private

    # @return [Boolean]
    def json_request?
      return false unless view_context.respond_to?(:search_state)

      view_context.search_state&.params&.dig(:format) == 'json'
    end
  end
end
