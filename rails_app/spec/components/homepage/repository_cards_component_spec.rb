# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::RepositoryCardsComponent, type: :component do
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

  it 'renders the section heading' do
    expect(component).to have_css('h2', text: I18n.t('homepage.regional_partnership.heading'))
  end

  it 'renders the intro paragraph with a browse-all link' do
    expect(component).to have_link(I18n.t('homepage.regional_partnership.browse_all'))
  end

  it 'renders the card grid' do
    expect(component).to have_css('ol.fa-cards')
  end

  it 'renders a card for each repository' do
    expect(component).to have_css('.fa-cards__card', count: 2)
  end

  it 'renders repository names as links to filtered search' do
    expect(component).to have_link('Test Repository')
    expect(component).to have_link('Another Repository')
  end

  it 'links to repository facet filter' do
    test_link = component.find_link('Test Repository')
    expect(test_link['href']).to include('repository_ssi')
    expect(test_link['href']).to include('Test+Repository')
  end

  it 'renders repository guide counts as subtitle text' do
    expect(component).to have_css('.fa-cards__card-sub', text: '100 guides')
    expect(component).to have_css('.fa-cards__card-sub', text: '200 guides')
  end

  context 'with an empty repository list' do
    before do
      render_inline(described_class.new(repos: []))
    end

    it 'renders the grid with no cards' do
      expect(component).to have_css('ol.fa-cards')
      expect(component).to have_no_css('.fa-cards__card')
    end
  end
end
