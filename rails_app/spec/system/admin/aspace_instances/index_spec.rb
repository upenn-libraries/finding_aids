# frozen_string_literal: true

require 'system_helper'

describe 'ASpaceInstances index page' do
  let(:user) { create(:user) }

  context 'when visiting as an unauthenticated user' do
    before do
      visit aspace_instances_path
    end

    it 'does not display user index page' do
      expect(page).not_to have_text('ASpace Instances')
    end

    it 'redirects to login page' do
      expect(page).to have_text 'You need to sign in or sign up before continuing.'
    end
  end

  context 'when visiting as an authenticated user' do
    let(:aspace_instance) { create(:aspace_instance, :with_endpoints) }

    before do
      aspace_instance
      sign_in user
      visit aspace_instances_path
    end

    it 'shows link to create new ASpace Instance' do
      expect(page).to have_link(I18n.t('admin.actions.create'), href: new_aspace_instance_path, count: 1)
    end

    it 'links to show page' do
      within(".table > tbody > .row-id-#{aspace_instance.id} > .slug") do
        expect(page).to have_link(aspace_instance.slug, href: aspace_instance_path(aspace_instance), count: 1)
      end
    end

    it 'shows the endpoint count' do
      within(".table > tbody > .row-id-#{aspace_instance.id} > .endpoint-count") do
        expect(page).to have_text(aspace_instance.endpoints.count)
      end
    end
  end
end
