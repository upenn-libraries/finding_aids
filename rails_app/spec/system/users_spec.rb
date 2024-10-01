# frozen_string_literal: true

require 'system_helper'

describe 'Users page' do
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
      sign_in user
      visit users_path
    end

    context 'when visiting the index page' do
      before { visit users_path }

      it 'lists user information' do
        expect(page).to have_text user.email
        expect(page).to have_link user.email, href: user_path(user.id)
      end

      it 'shows an add user button' do
        expect(page).to have_link 'Add User'
      end
    end

    context 'when visiting the show page' do
      before { visit user_path(user.id) }

      it 'shows user information' do
        expect(page).to have_text user.email
        expect(page).to have_text user.uid
      end

      it 'shows edit and delete buttons' do
        expect(page).to have_link 'Edit User'
        expect(page).to have_link 'Delete User'
      end
    end
  end
end
