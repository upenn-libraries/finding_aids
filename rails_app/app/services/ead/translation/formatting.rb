# frozen_string_literal: true

module Ead
  module Translation
    # Translate XML format attributes to HTML
    class Formatting
      # @param node [Nokogiri::XML::Node]
      # @param method [Symbol]
      # @return[Nokogiri::XML::Node]
      def to_html(node, method)
        method.present? && self.class.method_defined?(method) ? send(method, node) : generic_emphasis(node)
      end

      def underline(node)
        transform node: node, name: 'span', css_class: 'underline'
      end

      def super(node)
        transform node: node, name: 'sup'
      end

      def sub(node)
        transform node: node, name: 'sub'
      end

      def bold(node)
        transform node: node, name: 'strong'
      end

      def italic(node)
        transform node: node, name: 'em'
      end

      def smcaps(node)
        transform node: node, name: 'span', css_class: 'small-caps'
      end

      def doublequote(node)
        transform node: node, name: 'span', content: "\"#{node.text}\""
      end

      def singlequote(node)
        transform node: node, name: 'span', content: "'#{node.text}'"
      end

      def bolditalic(node)
        transform node: node, name: 'em', wrap: '<strong></strong>'
      end

      def boldunderline(node)
        transform node: node, name: 'string', css_class: 'underline'
      end

      def boldsmcaps(node)
        transform node: node, name: 'strong', css_class: 'small-caps'
      end

      def bolddoublequote(node)
        transform node: node, name: 'strong', content: "\"#{node.text}\""
      end

      def boldsinglequote(node)
        transform node: node, name: 'strong', content: "'#{node.text}'"
      end

      def generic_emphasis(node)
        return unless node.name == 'emph'

        transform(node: node, name: 'em')
      end

      private

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
end
