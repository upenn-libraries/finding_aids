# frozen_string_literal: true

require 'system_helper'

describe 'Static Pages' do
  context 'when visiting the About page' do
    it 'renders the header' do
      visit about_path
      expect(page).to have_text('About the Philadelphia Area Archives Site')
    end
  end
end
