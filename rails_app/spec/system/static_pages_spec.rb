# frozen_string_literal: true

require 'system_helper'

describe 'Static Pages' do
  context 'when visiting the About page' do
    it 'renders the header and sections' do
      visit about_path
      expect(page).to have_css('h1', text: I18n.t('about.header'))
      expect(page).to have_css('h2', text: I18n.t('about.headings.overview'))
    end
  end
end
