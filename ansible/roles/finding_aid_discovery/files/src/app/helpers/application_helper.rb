# frozen_string_literal: true

module ApplicationHelper
  # Custom helper method use by Blacklight to truncate abstract.
  def truncated_abstract(options)
    truncate(options[:value].first, length: 2_000, separator: ' ') do
      link_to '(see more)', solr_document_path(options[:document])
    end
  end
end
