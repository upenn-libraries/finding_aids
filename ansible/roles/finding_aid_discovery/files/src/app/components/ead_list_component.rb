# frozen_string_literal: true

# Converts EAD list elements to valid HTML list markup.
class EadListComponent < ViewComponent::Base
  attr_reader :node

  # @param [Nokogiri::XML::Element] list_node
  def initialize(list_node:)
    @node = list_node
  end

  def render?
    node.present?
  end

  def list_type
    node.attr(:type)
  end

  def call
    sanitize convert_to_html
  end

  # Apply transformations from ead list syntax to html syntax
  def convert_to_html
    case list_type
    when 'deflist'
      convert_deflist
    else
      raise "bad list_type #{list_type}"
    end
    node.children.to_html
  end

  def convert_deflist
    headers = node.at_xpath('./listhead').elements.map(&:text)
    values = node.xpath('./defitem').map do |e|
      [e.at_xpath('label').text, e.at_xpath('item').text]
    end
    byebug
  end
end
