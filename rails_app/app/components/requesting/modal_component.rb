# frozen_string_literal: true

module Requesting
  # Renders the request modal that supports submitting requests to Aeon.
  class ModalComponent < ViewComponent::Base
    attr_reader :repository_name

    # @param repository_name [String]
    def initialize(repository_name:)
      @repository_name = repository_name
    end
  end
end
