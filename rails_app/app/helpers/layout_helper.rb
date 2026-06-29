# frozen_string_literal: true

# Local overrides for Blacklight layout helpers.
module LayoutHelper
  include Blacklight::LayoutHelperBehavior

  # Use a full-width (container-fluid) layout for the search results page so the
  # results grid spans the viewport. Everything else — including the homepage,
  # which is also catalog#index but has no search parameters — keeps the default
  # fixed-width container (constrained to the design-system viewport margins).
  #
  # Setting config.full_width_layout in CatalogController would apply globally;
  # this scopes the full-width treatment to results only.
  # @return [String]
  def container_classes
    catalog_results_page? ? 'container-fluid' : 'container'
  end

  # @return [Boolean] true on the catalog results page (catalog#index with a search)
  def catalog_results_page?
    controller_name == 'catalog' && action_name == 'index' && has_search_parameters?
  end
end
