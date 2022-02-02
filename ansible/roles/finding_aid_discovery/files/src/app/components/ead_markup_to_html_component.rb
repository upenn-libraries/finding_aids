# Converts EAD markup to valid HTML markup
class EadMarkupToHtmlComponent < ViewComponent::Base
  attr_reader :node

  def initialize(node:)
    @node = node
  end

  def call
    sanitize convert_to_html
  end

  def convert_to_html
    # apply transformations from ead syntax to html syntax
    node.xpath('//head').each do |h| # not needed for title conversion
      h.name = 'strong'
      h.wrap('<div></div>')
    end
    node.xpath('//emph').each { |e| e.name = 'em'}
    node.xpath('//lb').each   { |l| l.name = 'br'}

    node.to_html
  end
end
