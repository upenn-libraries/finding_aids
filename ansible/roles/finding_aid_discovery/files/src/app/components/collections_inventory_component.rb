# frozen_string_literal: true

# Renders display information for Collection Inventory
class CollectionsInventoryComponent < ViewComponent::Base
  attr_accessor :node

  # @param [Nokogiri::XML::Element] node
  # @param [TrueClass, FalseClass] requestable
  # @param [Hash] requesting_info
  def initialize(node:, requestable:, requesting_info:)
    @node = node
    @requestable = requestable
    @requesting_info = requesting_info
  end

  def call
    render(CollapsableSectionComponent.new(id: t('sections.collection_inventory').parameterize)) do |c|
      c.title { t('sections.collection_inventory') }
      c.body do
        if @requestable
          collection_component_with_form
        else
          render(CollectionsComponent.new(node: node, level: 1))
        end
      end
    end
  end

  private

  def collection_component_with_form
    form_with url: new_request_path, method: :get, id: 'aeonRequestForm' do |form|
      safe_join([
                  form.hidden_field(:call_num, value: @requesting_info[:call_num]),
                  form.hidden_field(:title, value: @requesting_info[:title]),
                  form.hidden_field(:repository, value: @requesting_info[:repository]),
                  render(CollectionsComponent.new(node: node, level: 1, requestable: true)),
                  form.submit('Request to view selected materials', class: 'btn btn-primary')
                ])
    end
  end
end
