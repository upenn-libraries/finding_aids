# frozen_string_literal: true

require 'system_helper'

describe 'Blacklight' do
  it 'renders as expected' do
    visit root_path
    expect(page).to have_text 'Welcome'
  end
end
