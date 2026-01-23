# frozen_string_literal: true

require 'system_helper'

describe 'Users index page' do
  let(:user) { create(:user) }

  context 'when visiting as an unauthenticated user' do
    before do
      visit users_path
    end

    it 'does not display user index page' do
      expect(page).not_to have_text user.email
    end

    it 'redirects to login page' do
      expect(page).to have_text 'You need to sign in or sign up before continuing.'
    end
  end

  context 'when visiting as an authenticated user' do
    before do
      login_as user
      visit users_path
    end

    it 'lists user information' do
      expect(page).to have_text user.email
      expect(page).to have_link user.email, href: user_path(user.id)
    end

    it 'shows an add user button' do
      expect(page).to have_link(I18n.t('admin.actions.create'), href: new_user_path)
    end
  end
end
