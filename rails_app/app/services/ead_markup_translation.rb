# frozen_string_literal: true

# Converts EAD markup to valid HTML markup.
class EadMarkupTranslation
  class << self
    # NOTE: `sanitize` here strips "unsafe" tags and attributes. See
    # ActionView::Base.sanitized_allowed_attributes and ActionView::Base.sanitized_allowed_tags
    # for preserved attributes and tags
    # @param node [Nokogiri::XML::Node]
    # @param remove_head [Boolean]
    # @return [ActiveSupport::SafeBuffer, nil]
    def call(node:, remove_head: false)
      return if node.blank?

      node.at_xpath('head')&.remove if remove_head
      sanitized = sanitizer.sanitize(convert_to_html(node), attributes: preserved_attributes)
      ActiveSupport::SafeBuffer.new(sanitized)
    end

    # @return [Rails::HTML5::SafeListSanitizer]
    def sanitizer
      @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end

    # @return [Array]
    def preserved_attributes
      @preserved_attributes ||= ActionView::Base.sanitized_allowed_attributes + %w[target rel]
    end

    private

    # Apply transformations from ead syntax to html syntax
    def convert_to_html(node)
      convert_head(node)
      convert_lists(node)
      transform_blockquotes(node)
      convert_extrefs(node)
      convert_line_breaks(node)
      convert_formatting_markup(node)
      node.children.to_html
    end

    def convert_head(node)
      node.xpath('.//head').each do |h|
        h.name = 'strong'
        h.wrap('<div></div>')
      end
    end

    def convert_line_breaks(node)
      node.xpath('.//lb').each { |l| l.name = 'br' }
    end

    def transform_blockquotes(node)
      node.xpath('.//blockquote').each { |b| b.set_attribute('class', 'blockquote mx-5') }
    end

    # Converts EAD2-spec 'extref' nodes to <a> tags. EAD3 removed <extref>. Note that
    # attributes on these nodes are namespaced with 'xlink:' but out removal of namespaces
    # gets rid of those.
    def convert_extrefs(node)
      node.xpath('.//extref').each do |link|
        url = link.attr('href')
        next unless url

        link.xpath('.//@*').remove
        link.name = 'a'
        link.set_attribute('href', url)
        link.set_attribute('target', '_blank')
        link.set_attribute('rel', 'noopener')
      end
    end

    def convert_lists(node)
      node.xpath('.//list').each do |list|
        case list.attr('type')
        when 'deflist'
          list.name = 'dl'
          list.at_xpath('.//listhead')&.remove # TODO: remove listhead for now, otherwise we have to build a table?
          list.xpath('.//defitem').each do |defitem|
            defitem.xpath('.//label').each do |label|
              label.name = 'dt'
              label.parent = list
            end
            defitem.xpath('.//item').each do |item|
              item.name = 'dd'
              item.parent = list
            end
            defitem.remove
          end
        when 'unordered', 'marked'
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

    def convert_formatting_markup(node)
      node.xpath('.//emph | .//title | .//titleproper').each do |e|
        case e.attr('render')
        when 'underline'
          transform node: e, name: 'span', css_class: 'underline'
        when 'super'
          transform node: e, name: 'sup'
        when 'sub'
          transform node: e, name: 'sub'
        when 'bold'
          transform node: e, name: 'strong'
        when 'italic'
          transform node: e, name: 'em'
        when 'smcaps'
          transform node: e, name: 'span', css_class: 'small-caps'
        when 'doublequote'
          transform node: e, name: 'span', content: "\"#{e.text}\""
        when 'singlequote'
          transform node: e, name: 'span', content: "'#{e.text}'"
        when 'bolditalic'
          transform node: e, name: 'em', wrap: '<strong></strong>'
        when 'boldunderline'
          transform node: e, name: 'string', css_class: 'underline'
        when 'boldsmcaps'
          transform node: e, name: 'strong', css_class: 'small-caps'
        when 'bolddoublequote'
          transform node: e, name: 'strong', content: "\"#{e.text}\""
        when 'boldsinglequote'
          transform node: e, name: 'strong', content: "'#{e.text}'"
        else
          transform(node: e, name: 'em') if e.name == 'emph'
        end
        e.delete('render')
      end
    end

    # @param [Object] node
    # @param [String, NilClass] name
    # @param [String, NilClass] css_class
    # @param [String, NilClass] wrap
    # @param [String, NilClass] content
    def transform(node:, name: nil, css_class: nil, wrap: nil, content: nil)
      node.name = name if name
      node.set_attribute('class', css_class) if css_class
      node.wrap(wrap) if wrap
      node.content = content if content
    end
  end
end
