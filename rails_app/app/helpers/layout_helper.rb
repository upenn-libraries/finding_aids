# frozen_string_literal: true

# Local overrides for Blacklight layout helpers
module LayoutHelper
  include Blacklight::LayoutHelperBehavior

  # Set content for the page title, which Blacklight's base layout reads and renders in <title>.
  # Produces "Title · Document title · Application name" (document_title optional), matching the
  # page-title pattern used in Find and Digital Collections.
  # @param title [String] the title of the page
  # @param document_title [String, nil] the title of the document
  # @return [String]
  def page_title(title, document_title: nil)
    content_for(:page_title) { [title, document_title, application_name].compact.join(' · ') }
  end
end
