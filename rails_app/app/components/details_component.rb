# frozen_string_literal: true

# Renders details at different levels
class DetailsComponent < ViewComponent::Base
  renders_one :body

  # @param header_id [String]
  # @param header [String]
  # @param header_tag [Symbol]
  def initialize(header_id:, header:, header_tag: :h3)
    @header_id = header_id
    @header_text = header
    @header_tag = header_tag
  end

  # @return [Boolean]
  def render?
    rendered_body.present?
  end

  # @return [String]
  def rendered_body
    @rendered_body ||= body.to_s
  end

  # @return [ActiveSupport::SafeBuffer]
  def header
    content_tag(@header_tag, id: @header_id) { @header_text }
  end
end
