# frozen_string_literal: true

# Utility methods to help test Ead XML processing
module EadHelpers
  # @param xml [String]
  # @param xpath [String]
  # @return [Ead::Extraction::Inventory::Entry]
  def entry_for(xml, xpath: '//c | //c01 | //c02 | //c03')
    node = Nokogiri::XML(xml).at_xpath(xpath)
    Ead::Extraction::Inventory::Entry.new(node)
  end
end
