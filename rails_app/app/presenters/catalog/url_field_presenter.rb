# frozen_string_literal: true

module Catalog
  # Custom Blacklight::FieldPresenter subclass based on Blacklight 9.0.0
  class UrlFieldPresenter < Catalog::FieldPresenter
    # @return [Array]
    def values
      @values ||= if json_request?
                    super
                  else
                    retrieve_values.map { |value| view_context.link_to(value, value) }
                  end
    end
  end
end
