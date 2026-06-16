# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::CollectionGuideCardsComponent, type: :component do
  subject(:component) { page }

  let(:guides) do
    [
      HomepageData::CollectionGuide.new(identifier: 'TEST.001', name: 'Test Collection', collection: 'Test Institution'),
      HomepageData::CollectionGuide.new(identifier: 'TEST.002', name: 'Another Collection', collection: 'Another Institution')
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

  it 'renders guide names as links to records' do
    expect(component).to have_link('Test Collection', href: '/catalog/TEST.001')
    expect(component).to have_link('Another Collection', href: '/catalog/TEST.002')
  end

  it 'renders guide collection names as subtitle text' do
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
