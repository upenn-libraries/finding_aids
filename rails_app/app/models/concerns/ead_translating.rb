# frozen_string_literal: true

# Shareable module to call translation service
module EadTranslating
  # @param node [Nokogiri::XML::Node]
  # @param remove_head [Boolean]
  # @return [ActiveSupport::SafeBuffer, nil]
  def translate(node:, remove_head: false)
    Ead::Translation::Service.call(node: node, remove_head: remove_head)
  end
end
