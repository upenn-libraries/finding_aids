# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Homepage::CollectionGuideCardsComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:component) { page }

  let(:guide_one) { build(:featured_collection) }
  let(:guide_two) { build(:featured_collection) }

  before do
    render_inline(described_class.new(guides: [guide_one, guide_two]))
  end

  it 'renders the section heading' do
    expect(component).to have_css('h2', text: I18n.t('homepage.collection_guides.heading'))
  end

  it 'renders the card grid' do
    expect(component).to have_css('ol.fa-cards')
  end

  it 'renders a card for each guide' do
    expect(component).to have_css('.fa-card', count: 2)
  end

  it 'renders guide names as record page links' do
    expect(component).to have_link(guide_one.title, href: solr_document_path(id: guide_one.record_id))
    expect(component).to have_link(guide_two.title, href: solr_document_path(id: guide_two.record_id))
  end

  it 'renders guide repository names as subtitle text' do
    expect(component).to have_css('.fa-card__description', text: guide_one.repository)
    expect(component).to have_css('.fa-card__description', text: guide_two.repository)
  end

  context 'with an empty guide list' do
    before do
      render_inline(described_class.new(guides: []))
    end

    it 'renders the grid with no cards' do
      expect(component).to have_css('ol.fa-cards')
      expect(component).to have_no_css('.fa-card')
    end
  end
end
