# frozen_string_literal: true

# Renders additional information area on record show page
class AdditionalInformationComponent < ViewComponent::Base
  attr_reader :node, :title

  # @param [String] title
  # @param [Nokogiri::XML::Element] node
  def initialize(title:, node:)
    @node = node
    @title = title
  end

  def render?
    node.present?
  end

  def call
    render(CollapsableSectionComponent.new(id: title.parameterize)) do |c|
      c.title { title }
      c.body { render(EadMarkupTranslationComponent.new(node: node, remove_head: true)) }
    end
  end
end
