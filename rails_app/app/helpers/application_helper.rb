# frozen_string_literal: true

module ApplicationHelper
  # Custom helper method use by Blacklight to truncate abstract.
  # @param [Hash] options
  # @return [ActiveSupport::SafeBuffer]
  def truncated_abstract(options)
    truncate(options[:value].first, length: 1_000, separator: ' ') do
      link_to '(see more)', solr_document_path(options[:document])
    end
  end

  # @param [Hash] options
  def extent_display(options)
    options[:value].one? ? options[:value].first : unordered_list(options)
  end

  # @param [Hash] options
  # @return [ActiveSupport::SafeBuffer]
  def unordered_list(options)
    content_tag :ul do
      options[:value].map do |item|
        concat content_tag(:li, item)
      end
    end
  end
end
