# frozen_string_literal: true

# Renders details at different levels
class DetailsComponent < ViewComponent::Base
  renders_one :body

  HEADING_OFFSET = 2
  HEADING_MAX = 6

  # @param heading_id [String]
  # @param heading [String]
  # @param container_class [String]
  # @param level [Integer]
  def initialize(heading_id:, heading:, container_class: nil, level: 1, requestable: false)
    @heading_id = heading_id
    @heading_text = heading
    @container_class = container_class
    @level = level
    @requestable = requestable
  end

  # @return [Boolean]
  def render?
    rendered_body.present?
  end

  # @return [String]
  def rendered_body
    @rendered_body ||= body.to_s
  end

  # @return [Symbol]
  def heading_tag
    heading_level = @level + HEADING_OFFSET
    heading_level = [heading_level, HEADING_MAX].min
    "h#{heading_level}".to_sym
  end

  # @return [ActiveSupport::SafeBuffer]
  def heading
    request_span = content_tag(:span, nil, class: 'fa-visit__section-count fa-small-name') if @requestable

    content_tag(heading_tag, id: @heading_id) { safe_join [@heading_text, request_span] }
  end

  # @return [String]
  def details_class
    subseries_class = 'fa-guide__details--subseries' if @level > 1
    ['fa-guide__details', subseries_class].join(' ')
  end
end
