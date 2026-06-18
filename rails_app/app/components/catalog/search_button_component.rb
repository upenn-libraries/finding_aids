# frozen_string_literal: true

# Overrides Blacklight::SearchButtonComponent from Blacklight 9.0.0 to render a visible text
# label (e.g. "Search") rather than Blacklight's icon with a hidden label. A visible label
# offers more affordances, such as being able to target the control with voice control.
module Catalog
  # Overrides Blacklight::SearchButtonComponent to render a visible text
  # label rather than an icon with a hidden label.
  class SearchButtonComponent < Blacklight::SearchButtonComponent
    def call
      tag.button(@text, class: 'pl-button pl-button--accent search-btn', type: 'submit', id: @id)
    end
  end
end
