# frozen_string_literal: true

module Catalog
  # Copied from Blacklight 8.12.3 to enable customization of header/title for results page
  class DocumentTitleComponent < Blacklight::DocumentTitleComponent
    def title
      text = presenter.heading
      text += ", #{@document.display_dates.join(' ')}" if @document.display_dates.any?
      @view_context.link_to_document presenter.document, text, itemprop: 'name'
    end
  end
end
