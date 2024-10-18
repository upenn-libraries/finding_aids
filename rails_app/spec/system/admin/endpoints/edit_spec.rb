# frozen_string_literal: true

require 'system_helper'

describe 'Endpoints edit page' do
  let(:user) { create(:user) }

  before do
    sign_in user
    visit edit_endpoint_path(endpoint)
  end

  context 'when viewing the form' do
    let(:endpoint) { create(:endpoint, :aspace_harvest) }

    it 'disables the slug field' do
      expect(page).to have_field('Slug', type: :text, disabled: true)
    end

    it 'pre-selects source type' do
      expect(page).to have_select('Source type', selected: endpoint.source_type, options: Endpoint::SOURCE_TYPES)
    end

    it 'pre selects aspace instance' do
      expect(page).to have_select('ASpace instance', selected: endpoint.aspace_instance.slug,
                                                     options: [I18n.t('admin.endpoints.aspace_instance.include_blank'),
                                                               ASpaceInstance.first.slug])
    end
  end

  context 'when successfully updating an endpoint' do
    let(:endpoint) { create(:endpoint, :webpage_harvest) }

    before do
      fill_in 'Webpage url', with: 'https://new_url.edu'
      click_on 'Save'
    end

    it 'displays the flash notice' do
      expect(page).to have_text I18n.t('admin.flash.update.success', class_name: endpoint.class,
                                                                     identifier: endpoint.slug)
    end

    it 'displays the updated values' do
      expect(page).to have_text 'https://new_url.edu'
    end
  end

  context 'when failing to update an endpoint' do
    let(:endpoint) { create(:endpoint, :aspace_harvest) }

    before do
      select 'webpage', from: 'Source type'
      click_on 'Save'
    end

    it 'displays the flash alert' do
      endpoint.source_type = 'webpage'
      endpoint.validate
      error = endpoint.errors.map(&:full_message).join(', ')
      expect(page).to have_text I18n.t('admin.flash.update.failure', class_name: endpoint.class,
                                                                     identifier: endpoint.slug, error: error)
    end

    it 'renders the form' do
      expect(page).to have_text "Edit Endpoint #{endpoint.slug}"
    end
  end
end
