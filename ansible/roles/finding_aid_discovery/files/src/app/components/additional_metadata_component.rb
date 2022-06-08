# frozen_string_literal: true

# Renders additional metadata present in the EAD by reformating the specified sections of the EAD into HTML.
class AdditionalMetadataComponent < ViewComponent::Base
  attr_reader :nodes

  # @param [Nokogiri::XML::NodeSet, Nokogiri::XML::Element] nodes
  def initialize(nodes:)
    @nodes = Array.wrap(nodes) # ensure a Nokogiri::XML::Element will respond to iterable methods
  end

  def render?
    nodes.any?
  end

  def call
    safe_join(nodes.map { |node| render(EadMarkupTranslationComponent.new(node:, remove_head: true)) })
  end
end
