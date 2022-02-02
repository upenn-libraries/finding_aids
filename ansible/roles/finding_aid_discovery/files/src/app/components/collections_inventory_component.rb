class CollectionsInventoryComponent < ViewComponent::Base
  def initialize(xml:)
    @xml = Nokogiri::XML.parse(xml)
    @xml.remove_namespaces!
  end

  def call
    content_tag(:h4, 'Collection Inventory') + render(CollectionsComponent.new(node: @xml.at_xpath('/ead/archdesc/dsc'), level: 1))
  end
end