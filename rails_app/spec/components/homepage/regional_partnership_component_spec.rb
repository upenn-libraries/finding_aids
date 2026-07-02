# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::RegionalPartnershipComponent, type: :component do
  subject(:component) { page }

  let(:repos) do
    [
      HomepageData::Repository.new(name: 'Test Repository', slug: 'test', count: 100, lat: 39.95, lng: -75.16,
                                   records_url: '/records?f%5Brepository_ssi%5D%5B%5D=Test%20Repository'),
      HomepageData::Repository.new(name: 'Another Repository', slug: 'another', count: 200, lat: 40.0, lng: -75.19,
                                   records_url: '/records?f%5Brepository_ssi%5D%5B%5D=Another%20Repository')
    ]
  end

  before do
    render_inline(described_class.new(repos: repos))
  end

  it 'renders the regional partnership section' do
    expect(component).to have_css('section.fa-regional-partnership')
  end

  it 'renders the map div with the Stimulus controller' do
    expect(component).to have_css('#partnership-map.fa-regional-partnership__map[data-controller="map"]')
  end

  it 'renders the section heading from the card component' do
    expect(component).to have_css('h2', text: I18n.t('homepage.regional_partnership.heading'))
  end

  it 'renders repository links from the card component' do
    expect(component).to have_link('Test Repository')
    expect(component).to have_link('Another Repository')
  end

  context 'when no repos are present' do
    before do
      render_inline(described_class.new(repos: []))
    end

    it 'renders nothing' do
      expect(component).to have_no_css('section.fa-regional-partnership')
    end
  end
end
