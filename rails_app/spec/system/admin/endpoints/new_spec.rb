# frozen_string_literal: true

require 'system_helper'

describe 'Endpoints new page' do
  let(:user) { create(:user) }

  before do
    sign_in user
    create(:aspace_instance)
    visit new_endpoint_path
  end

  context 'when viewing the form' do
    it 'displays a slug field' do
      expect(page).to have_field('Slug', type: :text, disabled: false)
    end

    it 'displays contacts fields' do
      expect(page).to have_field('Public contacts', type: :text)
      expect(page).to have_field('Tech contacts', type: :text)
    end

    it 'displays a dropdown to select source type' do
      expect(page).to have_select('Source type', selected: 'webpage', options: Endpoint::SOURCE_TYPES)
    end

    it 'displays webpage url field' do
      expect(page).to have_field('Webpage url', type: :text)
    end

    it 'displays a dropdown to select the aspace instance' do
      expect(page).to have_select('ASpace instance', selected: I18n.t('admin.endpoints.aspace_instance.include_blank'),
                                                     options: [I18n.t('admin.endpoints.aspace_instance.include_blank'),
                                                               ASpaceInstance.first.slug])
    end

    it 'displays aspace repo id field' do
      expect(page).to have_field('ASpace repo', type: :text)
    end
  end

  context 'when successfully creating a new endpoint' do
    let(:endpoint) { build(:endpoint, :webpage_harvest) }

    before do
      fill_in 'Slug', with: endpoint.slug
      fill_in 'Webpage url', with: endpoint.webpage_url
      click_on 'Save'
    end

    it 'displays flash alert' do
      expect(page).to have_text I18n.t('admin.flash.create.success', class_name: endpoint.class,
                                                                     identifier: endpoint.slug)
    end

    it 'redirects to the show page' do
      expect(page).to have_text 'Endpoint Summary'
    end
  end

  context 'when failing to create a new endpoint' do
    let(:endpoint) { build(:endpoint, :webpage_harvest, webpage_url: nil) }

    before do
      endpoint.validate
      visit endpoints_path
      click_on I18n.t('admin.actions.create')
      fill_in 'Slug', with: endpoint.slug
      click_on 'Save'
    end

    it 'displays flash alert' do
      error = endpoint.errors.map(&:full_message).join(', ')
      expect(page).to have_text I18n.t('admin.flash.create.failure', class_name: endpoint.class,
                                                                     identifier: endpoint.slug, error: error)
    end

    it 'renders the form' do
      expect(page).to have_text 'New Endpoint'
      expect(page).to have_field 'Slug', with: endpoint.slug
    end
  end
end
