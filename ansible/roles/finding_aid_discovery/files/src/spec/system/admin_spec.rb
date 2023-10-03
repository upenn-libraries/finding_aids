# frozen_string_literal: true

require 'system_helper'

describe 'Admin index page' do
  let(:user) { create(:user) }

  context 'when visiting as an authenticated user' do
    before do
      sign_in user
      visit admin_path
    end

    it 'displays admin index page' do
      expect(page).to have_text 'Admin'
    end
  end

  context 'when visiting as an unauthenticated user' do
    before do
      visit admin_path
    end

    it 'does not display admin index page' do
      expect(page).not_to have_text 'Admin'
    end

    it 'displays alert error message' do
      expect(page).to have_text 'You need to sign in or sign up before continuing.'
    end
  end
end
