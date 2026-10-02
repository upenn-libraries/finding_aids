# frozen_string_literal: true

# Renders the requesting bar and modal content if the document supports requesting
class RequestingComponent < ViewComponent::Base
  attr_reader :document

  VISIT_REQUEST = :visit
  SCAN_REQUEST = :scan

  # @param document [SolrDocument] the record
  def initialize(document:)
    @document = document
  end

  # Only render the requesting stuff if the document supports it and the configuration is present
  # @return [Boolean]
  def render?
    document.requestable? && repository_info.present?
  end

  # @return [Hash]
  def repository_info
    @repository_info ||= Settings.aeon.locations.find { |loc| loc[:label] == document.repository }
  end

  # @return [String]
  def repository_name
    repository_info[:label]
  end
end
