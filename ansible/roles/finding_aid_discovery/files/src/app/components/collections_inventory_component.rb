class CollectionsInventoryComponent < ViewComponent::Base
  def initialize(xml:)
    @xml = Nokogiri::XML.parse(xml)
    @xml.remove_namespaces!
  end

  def call
    render(CollapsableSectionComponent.new(id: 'collections-inventory')) do |c|
      c.title { 'Collection Inventory' }
      c.body { render(CollectionsComponent.new(node: @xml.at_xpath('/ead/archdesc/dsc'), level: 1)) }
    end
  end
end