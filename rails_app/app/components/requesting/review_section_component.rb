# frozen_string_literal: true

module Requesting
  # Renders dialog section for confirming the selection of items
  class ReviewSectionComponent < ViewComponent::Base
    attr_reader :request_type, :repository

    def initialize(request_type:, repository:)
      @request_type = request_type
      @repository = repository
    end

    def review_lede
      t("show.sections.request.#{request_type}.review_lede")
    end

    def list_area_target
      "#{request_type}ItemListArea"
    end
  end
end
