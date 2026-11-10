# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::StartOverButtonComponent, type: :component do
  before { render_inline(described_class.new) }

  it 'renders the SVG content inside the link' do
    expect(page).to have_css('a.catalog_startOverLink svg', visible: :all)
  end

  it 'renders a link to root_path' do
    expect(page).to have_css("a.catalog_startOverLink[href='#{Rails.application.routes.url_helpers.root_path}']")
  end

  it 'sets ARIA attributes' do
    expect(page.find('a.catalog_startOverLink')[:'aria-label']).to eq(I18n.t('blacklight.search.start_over'))
  end

  it 'sets tooltip attributes' do
    link = page.find('a.catalog_startOverLink')
    expect(link[:'data-controller']).to eq('tooltip')
    expect(link[:'data-bs-title']).to eq(I18n.t('blacklight.search.start_over'))
  end
end
