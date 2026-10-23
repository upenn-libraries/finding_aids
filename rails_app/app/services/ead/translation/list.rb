# frozen_string_literal: true

module Ead
  module Translation
    # Translate XML lists into HTML
    class List
      LISTS = %i[unordered ordered deflist marked].freeze

      # @param list [Nokogiri::XML::Node]
      # @param method [Symbol]
      # @return[Nokogiri::XML::Node, nil]
      def to_html(list, method)
        return unless method.in? LISTS

        send(method, list)
      end

      def deflist(list)
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
      end

      def unordered(list)
        list.name = 'ul'
        list.xpath('./item').each { |i| i.name = 'li' }
      end

      def ordered(list)
        list.name = 'ol'
        list.xpath('./item').each { |i| i.name = 'li' }
      end

      def marked(list)
        unordered(list)
      end
    end
  end
end
