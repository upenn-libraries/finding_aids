# frozen_string_literal: true

module Catalog
  # Decides whether to render language note
  class LanguageNotePresenter < FieldPresenter
    # render dynamically parsed language note if it's different from indexed language field
    # @return [Boolean]
    def render_field?
      note = document.extract(:language_note)
      languages = document.fetch(:languages_ssim, []).join

      note.present? && languages.gsub(/[^0-9a-zA-Z]/, '') != note.gsub(/[^0-9a-zA-Z]/, '')
    end
  end
end
