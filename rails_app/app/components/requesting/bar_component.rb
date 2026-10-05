# frozen_string_literal: true

module Requesting
  # Renders fixed bottom bar that kicks off the requesting interaction.
  class BarComponent < ViewComponent::Base
    attr_reader :document, :repository_info

    # Settings values from `aeon` key to include as data attributes for reference by Stimulus controller
    DATA_SETTINGS = %i[ere_endpoint].freeze

    # @param document [SolrDocument]
    # @param repository_info [Hash]
    def initialize(document:, repository_info:)
      @document = document
      @repository_info = repository_info
    end

    # Render tag for the "request bar" with attributes supporting Stimulus `RequestController` integration
    # @return [ActiveSupport::SafeBuffer]
    def wrapper_div(&content)
      content_tag('div', class: 'fa-request__bar', role: 'region', hidden: true,
                         aria: { label: t('show.sections.request.bar.region') },
                         data: bar_data_attributes) do
        capture(&content)
      end
    end

    # @return [ActiveSupport::SafeBuffer]
    def visit_button
      button type: RequestingComponent::VISIT_REQUEST
    end

    # @return [ActiveSupport::SafeBuffer]
    def scan_button
      button type: RequestingComponent::SCAN_REQUEST
    end

    private

    # @param type [Symbol]
    # @return [ActiveSupport::SafeBuffer]
    def button(type:)
      label = t("show.sections.request.bar.#{type}.button")
      tag.button(label, type: 'button', class: 'pl-button pl-button--success',
                        data: { action: 'click->request#initiateRequest',
                                'request-type-param': type })
    end

    # @return [Hash{String->String}]
    def bar_data_attributes
      { target: 'requestBar', active: 'false', title: document.title, call_num: document.call_num }
        .merge(repository_info)
        .merge(Settings.aeon.to_h.slice(*DATA_SETTINGS))
        .transform_keys { |key| "request-#{key}" }
    end
  end
end
