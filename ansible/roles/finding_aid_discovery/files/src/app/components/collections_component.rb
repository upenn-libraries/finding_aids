# frozen_string_literal: true

# Renders display information for all Collections
class CollectionsComponent < ViewComponent::Base
  def initialize(node:, level:, parent_id: 'collection', requestable: false)
    @level = level
    @parent_id = parent_id
    @collections = node.xpath('c | c01 | c02 | c03 | c04 | c05 | c06 | c07 | c08 | c09 | c10 | c11 | c12')
    @requestable = requestable
  end

  def call
    if @collections.any?
      safe_join(collections_components)
    elsif @level == 1
      no_collections
    end
  end

  def no_collections
    content_tag :div, class: 'alert alert-secondary', role: 'alert' do
      'Collection information not available.'
    end
  end

  def collections_components
    @collections.map.with_index do |c, i|
      render(
        CollectionComponent.new(
          node: c, level: @level, index: i + 1, id: "#{@parent_id}-#{i + 1}", requestable: @requestable
        )
      )
    end
  end
end
