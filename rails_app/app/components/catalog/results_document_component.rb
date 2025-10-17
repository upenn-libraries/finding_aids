# frozen_string_literal: true

module Catalog
  # Custom results page Document Component
  # Copied from Blacklight 8.4.0 to add repository info slot
  class ResultsDocumentComponent < Blacklight::DocumentComponent
    # Slot to render location details
    renders_one :repository_info, RepositoryInfoComponent

    def before_render
      super
      with_repository_info(document: @document) unless repository_info
    end
  end
end
