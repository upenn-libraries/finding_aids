# frozen_string_literal: true

module Requesting
  # Renders dialog section for submitting a request
  class SubmitSectionComponent < ViewComponent::Base
    attr_reader :request_type

    REQUEST_DATE_MINIMUM_WEEKS_OUT = 1

    INPUTS = {
      visit: %i[date notes save_for_later],
      scan: %i[notes save_for_later]
    }.freeze

    # @param request_type [Symbol]
    def initialize(request_type:)
      @request_type = request_type
    end

    # @return [String]
    def earliest_date_available
      REQUEST_DATE_MINIMUM_WEEKS_OUT.week.from_now.to_date.iso8601
    end

    # @return [ActiveSupport::SafeBuffer]
    def input_controls
      safe_join(INPUTS.fetch(request_type).map { |input| send(:"#{input}_input") })
    end

    private

    # @return [ActiveSupport::SafeBuffer]
    def notes_input
      tag.label do
        safe_join([
                    t('show.sections.request.notes_label'),
                    tag.textarea(name: 'Notes', rows: 3)
                  ])
      end
    end

    # @return [ActiveSupport::SafeBuffer]
    def save_for_later_input
      tag.label(class: 'fa-request__save') do
        safe_join([
                    tag.input(type: 'checkbox', name: 'rawUserReview', class: 'fa-request__checkbox', value: 'Yes'),
                    t('show.sections.request.user_review_label')
                  ])
      end
    end

    # @return [ActiveSupport::SafeBuffer]
    def date_input
      tag.div do
        tag.label do
          safe_join([t('show.sections.request.date_label'),
                     tag.span(t('show.sections.request.date_hint'), class: 'fa-request__hint pl-margin-b-xs'),
                     tag.input(type: 'date', name: 'rawScheduledDate', min: earliest_date_available, required: true)])
        end
      end
    end
  end
end
