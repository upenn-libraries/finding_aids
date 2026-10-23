# frozen_string_literal: true

module Ead
  # Shared abstractions for Extraction layer
  module Extraction
    # Allow Extraction objects to neatly label translations
    Definition = Data.define(:term, :translation)
  end
end
