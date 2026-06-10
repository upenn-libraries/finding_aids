# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/_home_text.html.erb', type: :view do
  include HomepageHelper

  before do
    # Stub helper methods to avoid random sampling in tests
    allow(view).to receive(:sample_collection_guides).and_return([
      OpenStruct.new(name: 'Test Collection', collection: 'Test Institution', identifier: 'TEST.001'),
      OpenStruct.new(name: 'Another Collection', collection: 'Another Institution', identifier: 'TEST.002')
    ])
    allow(view).to receive(:sample_repositories).and_return([
      OpenStruct.new(name: 'Test Repository', count: 100, lat: 39.95, lng: -75.16),
      OpenStruct.new(name: 'Another Repository', count: 200, lat: 40.0, lng: -75.19)
    ])
    allow(view).to receive(:all_repositories).and_return([])
    allow(view).to receive(:repository_facet_path).and_return('/records?f%5Brepository_ssi%5D%5B%5D=Test+Repository')
    allow(view).to receive(:search_action_path).and_return('/records')
    allow(view).to receive(:asset_path).and_return('/assets/hero/test.jpg')
    allow(Settings).to receive(:pennlibs_web_version).and_return('1.3.1')
  end

  it 'renders the hero section' do
    render
    expect(rendered).to have_css('pennlibs-hero')
    expect(rendered).to have_css('h1', text: 'Stories held in archives')
    expect(rendered).to have_css('pennlibs-header[theme="dark"]')
  end

  it 'renders the search form' do
    render
    expect(rendered).to have_css('form.paa-search-box')
    expect(rendered).to have_css('input[type="search"][name="q"]')
    expect(rendered).to have_css('button.pl-button--accent', text: 'Find it')
  end

  it 'renders the collection guides section' do
    render
    expect(rendered).to have_css('h2', text: 'Collection guides')
    expect(rendered).to have_css('ol.faa-cards', count: 2)
    expect(rendered).to have_css('.faa-cards__card-heading', text: 'Test Collection')
    expect(rendered).to have_css('.faa-cards__card-sub', text: 'Test Institution')
  end

  it 'renders the regional partnership section' do
    render
    expect(rendered).to have_css('h2', text: 'A regional partnership')
    expect(rendered).to have_css('.faa-cards__card-heading', text: 'Test Repository')
    expect(rendered).to have_css('.faa-cards__card-sub', text: '100 guides')
  end

  it 'renders the browse all institutions link' do
    render
    expect(rendered).to have_link('browse all institutions', href: '/records')
  end

  it 'renders the map container' do
    render
    expect(rendered).to have_css('#map')
  end

  it 'has a map container with Stimulus controller' do
    render
    expect(rendered).to have_css('#map[data-controller="map"]')
    expect(rendered).to have_css('#map[data-map-repos-value]')
  end

  it 'includes Leaflet CSS' do
    render
    expect(rendered).to have_css('link[href*="leaflet"][href*="leaflet.min.css"]', visible: false)
  end

  it 'includes Leaflet JS' do
    render
    expect(rendered).to have_css('script[src*="leaflet"][src*="leaflet.min.js"]', visible: false)
  end
end
