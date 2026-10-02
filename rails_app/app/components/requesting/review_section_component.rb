# frozen_string_literal: true

module Requesting
  # Renders dialog section for confirming the selection of items
  class ReviewSectionComponent < ViewComponent::Base
    attr_reader :request_type, :repository

    # @param request_type [String] scan or visit
    # @param repository [String] name for display
    def initialize(request_type:, repository:)
      @request_type = request_type
      @repository = repository
    end

    # @return [String]
    def review_lede
      t("show.sections.request.#{request_type}.review_lede")
    end

    # @return [String]
    def list_area_target
      "#{request_type}ItemList"
    end
  end
end
