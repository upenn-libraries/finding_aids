# frozen_string_literal: true

require 'system_helper'

describe 'Users show page' do
  let(:user) { create(:user) }

  before do
    sign_in user
    visit user_path(user.id)
  end

  it 'shows user information' do
    expect(page).to have_text user.email
    expect(page).to have_text user.uid
  end

  it 'shows edit and delete buttons' do
    expect(page).to have_link I18n.t('admin.actions.edit', href: edit_user_path(user))
    expect(page).to have_link I18n.t('admin.actions.destroy', href: user_path(user))
  end
end
