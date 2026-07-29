# frozen_string_literal: true

# Local overrides for Blacklight layout helpers.
module LayoutHelper
  include Blacklight::LayoutHelperBehavior

  # Setting config.full_width_layout in CatalogController would apply globally;
  # this scopes the full-width treatment to those pages only.
  # @return [String]
  def container_classes
    full_width_page? ? 'container-fluid' : 'container'
  end

  # @return [Boolean] true on the pages that should span the full viewport width
  def full_width_page?
    catalog_results_page? || catalog_show_page?
  end

  # @return [Boolean] true on the catalog results page (catalog#index with a search)
  def catalog_results_page?
    controller_name == 'catalog' && action_name == 'index' && has_search_parameters?
  end

  # @return [Boolean] true on the guide show page (catalog#show)
  def catalog_show_page?
    controller_name == 'catalog' && action_name == 'show'
  end
end
