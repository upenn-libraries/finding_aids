# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::RepositoryCardsComponent, type: :component do
  subject(:component) { page }

  let(:repos) do
    [
      OpenStruct.new(name: 'Test Repository', count: 100, lat: 39.95, lng: -75.16, slug: 'test'),
      OpenStruct.new(name: 'Another Repository', count: 200, lat: 40.0, lng: -75.19, slug: 'another')
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

  it 'renders repository names as links' do
    expect(component).to have_link('Test Repository')
    expect(component).to have_link('Another Repository')
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
