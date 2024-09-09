# frozen_string_literal: true

# Renders subjects and topics for record.
class TopicsComponent < ViewComponent::Base
  attr_accessor :topics

  # @param [Hash] topics
  def initialize(topics:)
    @topics = topics
  end

  def render?
    topics.any?
  end

  # @return [String]
  def call
    safe_join(
      @topics.map do |field, values|
        next if values.empty?

        content_tag(:h5, field_display_name(field)) +
          content_tag(:ul, class: 'list-unstyled') do
            safe_join(values.map { |v| content_tag(:li, facet_link_for(field, v)) })
          end
      end
    )
  end

  # @param [String] field for translation
  # @return [String]
  def field_display_name(field)
    t("fields.topics.#{field.to_s.split('_')[0]}")
  end

  # @param [Symbol] field to use in the facet link
  # @param [String] value to use as the designated facet
  # @return [ActiveSupport::SafeBuffer]
  def facet_link_for(field, value)
    link_to value, search_catalog_path("f[#{field}][]": value)
  end
end
