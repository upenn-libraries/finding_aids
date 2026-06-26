# frozen_string_literal: true

# Call translation service
module EadTranslating
  # @param node [Nokogiri::XML::Node]
  # @param remove_head [Boolean]
  def translate(node:, remove_head: false)
    translation.call(node: node, remove_head: remove_head)
  end

  private

  def translation
    @translation ||= Ead::Translation::Service
  end
end
