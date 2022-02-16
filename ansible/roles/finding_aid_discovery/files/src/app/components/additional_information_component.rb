# frozen_string_literal: true

# Renders additional information area on record show page
class AdditionalInformationComponent < ViewComponent::Base
  attr_reader :nodes, :title

  # @param [String] title
  # @param [Nokogiri::XML::NodeSet, Nokogiri::XML::Element] nodes
  def initialize(title:, nodes:)
    @nodes = Array.wrap(nodes) # ensure a Nokogiri::XML::Element will respond to iterable methods
    @title = title
  end

  def render?
    nodes.any?
  end

  def call
    render(CollapsableSectionComponent.new(id: title.parameterize)) do |c|
      c.title { title }
      c.body do
        safe_join(nodes.map { |node| render(EadMarkupTranslationComponent.new(node: node, remove_head: true)) })
      end
    end
  end
end
