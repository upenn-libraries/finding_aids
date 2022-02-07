# frozen_string_literal: true

# Rending Biography/History Component
class BiographyHistoryComponent < ViewComponent::Base
  attr_reader :node

  # @param [Nokogiri::XML::Element] node
  def initialize(node:)
    @node = node
  end

  def render?
    node.present?
  end

  def call
    render(CollapsableSectionComponent.new(id: 'biography-history')) do |c|
      c.title { 'Biography/History' }
      c.body { render(EadMarkupTranslationComponent.new(node: node, remove_head: true)) }
    end
  end
end
