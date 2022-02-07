# frozen_string_literal: true

# Renders Scope and Content component
class ScopeAndContentComponent < ViewComponent::Base
  attr_reader :node

  # @param [Nokogiri::XML::Element] node
  def initialize(node:)
    @node = node
  end

  def render?
    node.present?
  end

  def call
    render(CollapsableSectionComponent.new(id: 'scope-content')) do |c|
      c.title { 'Scope and Contents' }
      c.body { render(EadMarkupTranslationComponent.new(node: node, remove_head: true)) }
    end
  end
end
