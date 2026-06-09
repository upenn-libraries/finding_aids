# frozen_string_literal: true

# Overrides Blacklight::SearchNavbarComponent to use a simpler search bar
# without advanced search or autocomplete, wrapped in design system viewport margins.
class SearchNavbarComponent < Blacklight::SearchNavbarComponent
  def search_bar_component
    Blacklight::SearchBarComponent.new(
      url: helpers.search_action_url,
      params: helpers.search_state.params_for_search.except(:qt)
    )
  end
end
