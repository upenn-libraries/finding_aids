# frozen_string_literal: true

# Converts EAD markup to valid HTML markup.
class EadMarkupTranslationComponent < ViewComponent::Base
  attr_reader :node

  # @param [Nokogiri::XML::Element] node
  # @param [TrueClass, FalseClass] remove_head
  def initialize(node:, remove_head: false)
    node.at_xpath('head')&.remove if remove_head

    @node = node
  end

  def render?
    node.present?
  end

  def call
    sanitize convert_to_html
  end

  # Apply transformations from ead syntax to html syntax
  def convert_to_html
    node.xpath('.//head').each do |h|
      h.name = 'strong'
      h.wrap('<div></div>')
    end

    convert_lists

    node.xpath('.//lb').each { |l| l.name = 'br' }
    node.xpath('.//blockquote').each { |b| b.set_attribute('class', 'blockquote mx-5') }

    node.xpath('.//emph | .//title').each do |e|
      case e.attr('render')
      when 'underline'
        e.name = 'span'
        e.set_attribute('class', 'underline')
      when 'super'
        e.name = 'sup'
      when 'sub'
        e.name = 'sub'
      when 'bold'
        e.name = 'strong'
      when 'italic'
        e.name = 'em'
      else
        e.name = 'em' if e.name == 'emph'
      end
      e.delete('render')
    end

    node.children.to_html
  end

  def convert_lists
    node.xpath('.//list').each do |list|
      case list.attr('type')
      when 'deflist'
        list.name = 'dl'
        list.at_xpath('./listhead').remove # TODO: remove listhead for now, otherwise we have to build a table?
        list.xpath('./defitem').each do |defitem|
          defitem.xpath('./label').each do |label|
            label.name = 'dt'
            label.parent = list
          end
          defitem.xpath('./item').each do |item|
            item.name = 'dd'
            item.parent = list
          end
          defitem.remove
        end
      when 'unordered'
        list.name = 'ul'
        list.xpath('./item').each { |i| i.name = 'li' }
      when 'ordered'
        list.name = 'ol'
        list.xpath('./item').each { |i| i.name = 'li' }
      else
        next
      end
    end
  end
end
