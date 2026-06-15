# frozen_string_literal: true

module Catalog
  # Overriding component from Blacklight v9.0.0 to support:
  #   - combination of constraints/sort into one nav
  #   - removal of "did you mean" spellcheck suggestions area
  #   - usage of local StartOverButton component
  #   - remove heading_classes from the rendered constraints area
  class SearchHeaderComponent < Blacklight::SearchHeaderComponent
    def call
      tag.nav(class: 'fa-constraints-and-sort') do
        render(constraints) + render('sort_and_per_page')
      end
    end

    private

    def constraints
      helpers.blacklight_config
             .view_config(helpers.document_index_view_type)
             .constraints_component
             .new(
               search_state: helpers.search_state,
               heading_classes: nil,
               start_over_component: Catalog::StartOverButtonComponent
             )
    end
  end
end
