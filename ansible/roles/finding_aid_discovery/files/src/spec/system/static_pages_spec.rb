# frozen_string_literal: true

require 'system_helper'

describe 'Static Pages' do
  it 'renders About page' do
    visit about_path
    expect(page).to have_text('About the Philadelphia Area Archives Site')
  end

  it 'renders How to Use page' do
    visit how_to_use_path
    expect(page).to have_text('How to Use the Philadelphia Area Archives Site')
  end
end
