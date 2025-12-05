# frozen_string_literal: true

require 'system_helper'

describe 'Endpoints index page' do
  let(:user) { create(:user) }

  context 'when visiting as an unauthenticated user' do
    before do
      visit endpoints_path
    end

    it 'does not display user index page' do
      expect(page).not_to have_text('Endpoints')
    end

    it 'redirects to login page' do
      expect(page).to have_text 'You need to sign in or sign up before continuing.'
    end
  end

  context 'when visiting as an authenticated user' do
    let(:webpage_endpoint) { create(:endpoint, :webpage_harvest) }
    let(:aspace_endpoint) { create(:endpoint, :aspace_harvest, active: false) }

    before do
      webpage_endpoint
      aspace_endpoint
      login_as user
      visit endpoints_path
    end

    it 'shows link to create new endpoint' do
      expect(page).to have_link(I18n.t('admin.actions.create'), href: new_endpoint_path, count: 1)
    end

    it 'links to show page' do
      within('.table') do
        expect(page).to have_link(webpage_endpoint.slug, href: endpoint_path(webpage_endpoint), count: 1)
        expect(page).to have_link(aspace_endpoint.slug, href: endpoint_path(aspace_endpoint), count: 1)
      end
    end

    it 'lists endpoint data' do
      within('.table') do
        expect(page).to have_text(webpage_endpoint.source_type, count: 1)
        expect(page).to have_text(aspace_endpoint.source_type, count: 1)
      end
    end

    it 'lists endpoint status' do
      within('.table') do
        expect(page).to have_text(webpage_endpoint.active.to_s.titleize, count: 1)
        expect(page).to have_text(aspace_endpoint.active.to_s.titleize, count: 1)
      end
    end
  end
end
