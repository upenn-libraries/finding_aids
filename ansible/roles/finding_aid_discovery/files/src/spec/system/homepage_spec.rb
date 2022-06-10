# frozen_string_literal: true

require 'system_helper'

describe 'Homepage' do
  it 'includes the homepage copy area' do
    visit root_path
    expect(page).to have_css '.hpcontent'
  end

  it 'includes the homepage links area' do
    visit root_path
    expect(page).to have_css '.hplinks'
  end
end
