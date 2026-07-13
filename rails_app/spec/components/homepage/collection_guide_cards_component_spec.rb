# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::CollectionGuideCardsComponent, type: :component do
  subject(:component) { page }

  let(:guides) do
    [
      FeaturedCollection.new(title: 'Test Collection', repository: 'Test Institution'),
      FeaturedCollection.new(title: 'Another Collection', repository: 'Another Institution')
    ]
  end

  before do
    render_inline(described_class.new(guides: guides))
  end

  it 'renders the section heading' do
    expect(component).to have_css('h2', text: I18n.t('homepage.collection_guides.heading'))
  end

  it 'renders the intro paragraph' do
    expect(component).to have_css('p.pl-line-length',
                                  text: /#{I18n.t('homepage.collection_guides.intro').truncate(30)}/)
  end

  it 'renders the card grid' do
    expect(component).to have_css('ol.fa-cards')
  end

  it 'renders a card for each guide' do
    expect(component).to have_css('.fa-cards__card', count: 2)
  end

  it 'renders guide names as search links' do
    expect(component).to have_link('Test Collection',
                                   href: '/records?q=Test+Collection')
    expect(component).to have_link('Another Collection',
                                   href: '/records?q=Another+Collection')
  end

  it 'renders guide repository names as subtitle text' do
    expect(component).to have_css('.fa-cards__card-sub', text: 'Test Institution')
    expect(component).to have_css('.fa-cards__card-sub', text: 'Another Institution')
  end

  context 'with an empty guide list' do
    before do
      render_inline(described_class.new(guides: []))
    end

    it 'renders the grid with no cards' do
      expect(component).to have_css('ol.fa-cards')
      expect(component).to have_no_css('.fa-cards__card')
    end
  end
end
