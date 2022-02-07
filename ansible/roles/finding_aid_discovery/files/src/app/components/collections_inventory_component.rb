# frozen_string_literal: true

# Renders display information for Collection Inventory
class CollectionsInventoryComponent < ViewComponent::Base
  attr_accessor :node

  # @param [Nokogiri::XML::Element] node
  def initialize(node:)
    @node = node
  end

  def call
    render(CollapsableSectionComponent.new(id: 'collections-inventory')) do |c|
      c.title { 'Collection Inventory' }
      c.body { render(CollectionsComponent.new(node: node, level: 1)) }
    end
  end
end
