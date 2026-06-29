# frozen_string_literal: true

# Extract text from an XML node
module EadTextExtracting
  # @param node [Nokogori::XML::Node]
  # @return [String, nil]
  def text_only(node)
    node.try(:text).try(:strip)
  end
end
