# frozen_string_literal: true

require 'system_helper'

describe 'Repositories' do
  it 'has the appropriate title header' do
    visit repositories_path
    expect(page).to(
      have_selector('h1',
                    text: I18n.t('labels.titles.repositories_list'))
    )
  end
end
