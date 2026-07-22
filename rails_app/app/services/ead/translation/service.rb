# frozen_string_literal: true

module Ead
  module Translation
    # Converts EAD markup to valid HTML markup.
    class Service
      class << self
        # NOTE: `sanitize` here strips "unsafe" tags and attributes. See
        # ActionView::Base.sanitized_allowed_attributes and ActionView::Base.sanitized_allowed_tags
        # for preserved attributes and tags
        # @param node [Nokogiri::XML::Node]
        # @param remove_head [Boolean] remove head tag content from returned content
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

        # @return [Ead::Translation::Formatting]
        def formatting
          @formatting ||= Formatting.new
        end

        # @return [Ead::Translation::List]
        def list
          @list ||= List.new
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
          node.xpath('.//list').each do |list_node|
            type = list_node.attr('type')
            next unless type

            list.to_html(list_node, type.to_sym)
          end
        end

        def convert_formatting_markup(node)
          node.xpath('.//emph | .//title | .//titleproper').each do |element|
            attribute = element.attr('render')
            formatting.to_html(element, attribute&.to_sym)
            element.delete('render')
          end
        end
      end
    end
  end
end
