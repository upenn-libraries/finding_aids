# frozen_string_literal: true

# Overrides Blacklight::SearchNavbarComponent from Blacklight 9.0.0 to use the configured search bar
# component (or the default) without advanced search or autocomplete params.
# Set a custom search bar in the catalog controller via:
#   config.index.search_bar_component = MySearchBarComponent
module Catalog
  # Overrides Blacklight::SearchNavbarComponent to use the configured search bar
  # component without advanced search or autocomplete params.
  class SearchNavbarComponent < Blacklight::SearchNavbarComponent
    def search_bar_component
      search_bar_component_class.new(
        url: helpers.search_action_url,
        params: helpers.search_state.params_for_search.except(:qt)
      )
    end
  end
end
