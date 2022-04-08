# frozen_string_literal: true

# Renders display information for all Collections
class CollectionsComponent < ViewComponent::Base
  def initialize(node:, level:, form: nil)
    @level = level
    @collections = node.xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12')
    @form = form
  end

  def call
    safe_join(
      @collections.map do |c|
        render(CollectionComponent.new(node: c, level: @level, form: @form))
      end
    )
  end
end
