# frozen_string_literal: true

require 'system_helper'

describe 'ASpaceInstances edit page' do
  let(:user) { create(:user) }
  let(:aspace_instance) { create(:aspace_instance) }

  before do
    sign_in user
    visit edit_aspace_instance_path(aspace_instance)
  end

  context 'when viewing the form' do
    it 'displays a disabled slug field' do
      expect(page).to have_field('Slug', type: :text, disabled: true)
    end
  end

  context 'with a successful update' do
    before do
      fill_in 'Base url', with: 'https://new_url.edu'
      click_on 'Save'
    end

    it 'displays the flash notice' do
      expect(page).to have_text I18n.t('admin.flash.update.success', class_name: aspace_instance.class,
                                                                     identifier: aspace_instance.slug)
    end

    it 'displays the updated values' do
      expect(page).to have_text 'https://new_url.edu'
    end
  end

  context 'with a failed update' do
    before do
      fill_in 'Base url', with: ''
      click_on 'Save'
    end

    it 'displays the flash alert' do
      aspace_instance.base_url = ''
      aspace_instance.validate
      error = aspace_instance.errors.map(&:full_message).join(', ')
      expect(page).to have_text I18n.t('admin.flash.update.failure', class_name: aspace_instance.class,
                                                                     identifier: aspace_instance.slug, error: error)
    end

    it 'renders the form' do
      expect(page).to have_text "Edit ASpaceInstance #{aspace_instance.slug}"
    end
  end
end
