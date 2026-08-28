# frozen_string_literal: true

# Renders the multi-step request modal (`<dialog>`) and the fixed bottom bar
# that surfaces selected inventory items.
class RequestDialogComponent < ViewComponent::Base
  # @param document [SolrDocument] the record
  def initialize(document:)
    @repository_info = Settings.aeon.locations.find { |loc| loc[:label] == document.repository }
    @title = document.title
    @call_num = document.call_num
  end

  # @return [Boolean]
  def render?
    @repository_info.present?
  end

  # @return [String]
  def earliest_date_available
    1.week.from_now.to_date.iso8601
  end
end
