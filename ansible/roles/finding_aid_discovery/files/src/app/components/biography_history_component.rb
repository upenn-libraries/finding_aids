# frozen_string_literal: true

# Rending Biography/History Component
class BiographyHistoryComponent < ViewComponent::Base
  attr_reader :node

  def initialize(xml:)
    @xml = Nokogiri::XML.parse(xml)
    @xml.remove_namespaces!

    @node = @xml.at_xpath('/ead/archdesc/bioghist')
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
