# frozen_string_literal: true

require 'system_helper'

describe 'Admin index page' do
  let(:user) { create(:user) }

  context 'when visiting as an authenticated user' do
    before do
      sign_in user
      visit users_path
    end

    it 'displays users index page' do
      expect(page).to have_text user.email
    end
  end

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
end
