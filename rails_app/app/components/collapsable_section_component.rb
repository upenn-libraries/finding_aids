# frozen_string_literal: true

# Renders a collapsable section.
class CollapsableSectionComponent < ViewComponent::Base
  attr_reader :open

  renders_one :title
  renders_one :body

  # @param id [String]
  # @param open [Boolean]
  def initialize(id:, open: true)
    @collapsable_id = id
    @open = open
  end
end
