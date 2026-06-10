# frozen_string_literal: true

# Shared helper methods used across the application.
# Provides display helpers for search results and document metadata.
module ApplicationHelper
  # Truncate an abstract/value to 1,000 characters with a "see more" link.
  #
  # @param options [Hash] Blacklight field options with +:value+ and +:document+
  # @option options [Array<String>] :value the text values to truncate
  # @option options [SolrDocument] :document the document for linking
  # @return [ActiveSupport::SafeBuffer] truncated HTML
  def truncated_abstract(options)
    truncate(options[:value].first, length: 1_000, separator: ' ') do
      link_to '(see more)', solr_document_path(options[:document])
    end
  end

  # Format an extent field: single values render as plain text, multiple
  # values render as an unordered list.
  #
  # @param options [Hash] Blacklight field options with +:value+
  # @option options [Array<String>] :value the extent values
  # @return [ActiveSupport::SafeBuffer] formatted HTML
  def extent_display(options)
    options[:value].one? ? options[:value].first : unordered_list(options)
  end

  # Render an unordered list from Blacklight field values.
  #
  # @param options [Hash] Blacklight field options with +:value+
  # @option options [Array<String>] :value list items
  # @return [ActiveSupport::SafeBuffer] a +<ul>+ containing +<li>+ elements
  def unordered_list(options)
    content_tag :ul do
      safe_join(options[:value].map { |item| content_tag(:li, item) })
    end
  end
end
