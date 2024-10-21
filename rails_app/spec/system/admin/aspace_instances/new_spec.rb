# frozen_string_literal: true

require 'system_helper'

describe 'ASpaceInstances new page' do
  let(:user) { create(:user) }

  before do
    sign_in user
    visit new_aspace_instance_path
  end

  context 'when viewing the form' do
    it 'displays a slug field' do
      expect(page).to have_field('Slug', type: :text, disabled: false)
    end

    it 'displays base url field' do
      expect(page).to have_field('Base url', type: :text)
    end
  end

  context 'when successfully creating a new aspace instance' do
    let(:aspace_instance) { build(:aspace_instance) }

    before do
      fill_in 'Slug', with: aspace_instance.slug
      fill_in 'Base url', with: aspace_instance.base_url
      click_on 'Save'
    end

    it 'displays flash alert' do
      expect(page).to have_text I18n.t('admin.flash.create.success', class_name: aspace_instance.class,
                                                                     identifier: aspace_instance.slug)
    end

    it 'redirects to the show page' do
      expect(page).to have_text 'ASpace Instance Summary'
    end
  end

  context 'when failing to create a new aspace instance' do
    let(:aspace_instance) { build(:aspace_instance, base_url: nil) }

    before do
      visit new_aspace_instance_path
      fill_in 'Slug', with: aspace_instance.slug
      click_on 'Save'
    end

    it 'displays flash alert' do
      aspace_instance.validate
      error = aspace_instance.errors.map(&:full_message).join(', ')
      expect(page).to have_text I18n.t('admin.flash.create.failure', class_name: aspace_instance.class,
                                                                     identifier: aspace_instance.slug, error: error)
    end

    it 'renders the form' do
      expect(page).to have_text 'New ASpace Instance'
      expect(page).to have_field 'Slug', with: aspace_instance.slug
    end
  end
end
