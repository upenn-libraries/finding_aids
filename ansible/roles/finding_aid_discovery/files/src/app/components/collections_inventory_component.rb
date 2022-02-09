# frozen_string_literal: true

# Renders display information for Collection Inventory
class CollectionsInventoryComponent < ViewComponent::Base
  attr_accessor :node

  # @param [Nokogiri::XML::Element] node
  def initialize(node:)
    @node = node
  end

  def call
    render(CollapsableSectionComponent.new(id: t('sections.collection_inventory').parameterize)) do |c|
      c.title { t('sections.collection_inventory') }
      c.body { render(CollectionsComponent.new(node: node, level: 1)) }
    end
  end
end
