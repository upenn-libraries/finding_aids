# frozen_string_literal: true

module Catalog
  # Override component from Blacklight v9.0.0 to add an "All" constraint pill
  # when no search constraints are present.
  class ConstraintsComponent < Blacklight::ConstraintsComponent
    def initialize(show_all_constraint: true, **)
      super(**)

      @show_all_constraint = show_all_constraint
      @heading_classes = nil
    end

    def render?
      !no_constraints? || @show_all_constraint
    end

    def no_constraints?
      @search_state.query_param.blank? && @search_state.filters.empty?
    end

    def all_constraint
      tag.span(class: 'btn-group applied-filter constraint filter mx-1') do
        tag.span(class: 'constraint-value btn btn-outline-secondary') {
          tag.span(t('blacklight.search.filters.all'), class: 'filter-value')
        } + all_constraint_remove_button
      end
    end

    def all_constraint_remove_button
      helpers.link_to(helpers.root_path, class: 'btn btn-outline-secondary remove') do
        render(Blacklight::Icons::RemoveComponent.new(aria_hidden: true)) +
          tag.span(t('blacklight.search.filters.remove.value', value: 'All'), class: 'visually-hidden')
      end
    end
  end
end
