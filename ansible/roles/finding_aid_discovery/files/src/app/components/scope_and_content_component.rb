class ScopeAndContentComponent < ViewComponent::Base
  attr_reader :node

  def initialize(xml:)
    @xml = Nokogiri::XML.parse(xml)
    @xml.remove_namespaces!

    @node = @xml.at_xpath('/ead/archdesc/scopecontent')
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