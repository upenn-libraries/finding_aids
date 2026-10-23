# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeroPictureComponent, type: :component do
  subject(:component) { page }

  let(:image) { HomepageData.hero_images.sample }
  let(:picture_selector) { 'picture[hero="art-direction"]' }

  before do
    render_inline(described_class.new(image_data: image))
  end

  it 'renders a picture tag with hero attribute' do
    expect(component).to have_selector picture_selector
  end

  it 'renders a source tag' do
    within picture_selector do
      expect(component).to have_css 'source'
    end
  end

  it 'renders an image tag' do
    within picture_selector do
      expect(component).to have_css 'img'
    end
  end
end
