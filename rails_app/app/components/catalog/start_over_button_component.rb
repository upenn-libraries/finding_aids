# frozen_string_literal: true

module Catalog
  # Local component copied from Blacklight v9.0
  class StartOverButtonComponent < Blacklight::Component
    private

    ##
    # Start over from home page.
    def start_over_path(_query_params = params)
      helpers.root_path
    end
  end
end
