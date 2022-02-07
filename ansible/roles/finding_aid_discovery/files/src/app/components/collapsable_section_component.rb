# frozen_string_literal: true

# Renders a collapsable section.
class CollapsableSectionComponent < ViewComponent::Base
  renders_one :title
  renders_one :body

  # @param [String] id
  def initialize(id:)
    @collapsable_id = id
  end
end
