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
  # @return [ActiveSupport::SafeBuffer]
  def unordered_list(options)
    list_items = options[:value].map do |item|
      content_tag :li, item
    end
    content_tag :ul, list_items.join.html_safe
  end
end
