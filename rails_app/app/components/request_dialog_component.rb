# frozen_string_literal: true

# Renders the multi-step request modal (`<dialog>`) and the fixed bottom bar
# that supports submitting requests to Aeon.
class RequestDialogComponent < ViewComponent::Base
  # Settings values from `aeon` key to include as data attributes for reference by Stimulus controller
  DATA_SETTINGS = %i[ere_endpoint].freeze
  REQUEST_DATE_MINIMUM_WEEKS_OUT = 1

  attr_reader :document, :repository_info

  # @param document [SolrDocument] the record
  def initialize(document:)
    @document = document
    @repository_info = Settings.aeon.locations.find { |loc| loc[:label] == document.repository }
    @title = document.title
    @call_num = document.call_num
  end

  # Render the component if the document is considered requestable and the repository info is present
  # @return [Boolean]
  def render?
    document.requestable? && repository_info.present?
  end

  # Render tag for the "request bar" with attributes supporting Stimulus `RequestController` integration
  def bar_wrapper_div(&content)
    content_tag('div', class: 'fa-request__bar', role: 'region', hidden: true,
                       aria: { label: t('show.sections.request.bar.region') },
                       data: bar_data_attributes) do
      capture(&content)
    end
  end

  # @return [String]
  def earliest_date_available
    REQUEST_DATE_MINIMUM_WEEKS_OUT.week.from_now.to_date.iso8601
  end

  private

  def bar_data_attributes
    { target: 'requestBar', active: 'false', title: @title, call_num: @call_num }
      .merge(repository_info)
      .merge(Settings.aeon.to_h.slice(*DATA_SETTINGS))
      .transform_keys { |key| "request-#{key}" }
  end
end
