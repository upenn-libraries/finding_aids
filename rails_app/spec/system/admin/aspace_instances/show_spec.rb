# frozen_string_literal: true

require 'system_helper'

describe 'ASpaceInstances show page' do
  let(:user) { create(:user) }
  let(:aspace_instance) { create(:aspace_instance, :with_endpoints) }

  before do
    login_as user
    visit aspace_instance_path(aspace_instance)
  end

  it 'displays link to edit' do
    expect(page).to have_link(I18n.t('admin.actions.edit'), count: 1)
  end

  it 'displays link to delete' do
    expect(page).to have_link(I18n.t('admin.actions.destroy'), count: 1)
  end

  it 'displays slug' do
    expect(page).to have_text(aspace_instance.slug)
  end

  it 'displays base url' do
    expect(page).to have_text(aspace_instance.base_url)
  end

  it 'displays throttle' do
    expect(page).to have_text(aspace_instance.harvest_throttle)
  end

  it 'displays endpoints' do
    within('.table') do
      expect(page).to have_text(aspace_instance.endpoints.first.slug)
      expect(page).to have_text(aspace_instance.endpoints.second.slug)
    end
  end
end
