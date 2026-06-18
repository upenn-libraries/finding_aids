# frozen_string_literal: true

module Catalog
  # Override component from Blacklight v9.0.0 to add an "All" constraint pill
  # when no search constraints are present.
  class ConstraintsComponent < Blacklight::ConstraintsComponent
    # @return [Boolean]
    def render?
      true
    end

    # @return [Boolean]
    def constraints?
      @search_state.has_constraints?
    end

    # Return a constraint component representing the anti-constraint "All"
    # @return [Blacklight::ConstraintLayoutComponent]
    def all_constraint
      @query_constraint_component.new(
        value: t('blacklight.search.filters.all'),
        remove_path: helpers.root_path,
        classes: 'mx-1'
      )
    end
  end
end
