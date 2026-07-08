# frozen_string_literal: true

module Catalog
  # Custom Blacklight::FieldPresenter subclass based on Blacklight 9.0.0
  class EmailFieldPresenter < Catalog::FieldPresenter
    def values
      @values ||= if json_request?
                    super
                  else
                    retrieve_values.map { |value| view_context.mail_to(value, value) }.first
                  end
    end
  end
end
