class CollectionsComponent < ViewComponent::Base
  def initialize(node:, level:)
    @level = level
    @collections = node.xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12')
  end

  def call
    safe_join @collections.map { |c| render(CollectionComponent.new(node: c, level: @level)) }
  end
end