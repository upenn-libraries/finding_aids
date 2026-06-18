# frozen_string_literal: true

# Overrides Blacklight::SearchBarComponent from Blacklight 9.0.0 to apply the fa-search-box
# styling and render a custom search button with a visible label.
module Catalog
  # Overrides Blacklight::SearchBarComponent to apply the fa-search-box
  # styling and render a custom search button with a visible label.
  class SearchBarComponent < Blacklight::SearchBarComponent
    def initialize(**)
      super

      @classes = %w[fa-search-box]
    end

    # @return [Catalog::SearchButtonComponent]
    def default_search_button
      Catalog::SearchButtonComponent.new(id: "#{@prefix}search", text: t('search.button.label'))
    end
  end
end
