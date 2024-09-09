# frozen_string_literal: true

require 'system_helper'

describe 'Static Pages' do
  context 'when visiting the About page' do
    it 'renders the header' do
      visit about_path
      expect(page).to have_text('About the Philadelphia Area Archives Site')
    end
  end

  context 'when visiting the How to Use page' do
    it 'renders the header' do
      visit how_to_use_path
      expect(page).to have_text('How to Use the Philadelphia Area Archives Site')
    end
  end
end
