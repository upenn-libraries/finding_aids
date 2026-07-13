# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DetailsComponent, type: :component do
  describe 'rendering' do
    it 'does not render without a body' do
      component = described_class.new(heading_id: 'test-id', heading: 'Test')
      render_inline component

      expect(page).not_to have_css('details')
      expect(component.render?).to be false
    end

    it 'adds base styles and heading tag at level 1' do
      render_inline(described_class.new(heading_id: 'series-1', heading: 'Correspondence', level: 1)) do |component|
        component.with_body { 'Some content' }
      end
      expect(page).to have_css('details.fa-guide__details summary h3#series-1', text: 'Correspondence', visible: :all)
      expect(page).not_to have_css('details.fa-guide__details--subseries', visible: :all)
    end

    it 'adds the subseries styles and heading tag above level 1' do
      render_inline(described_class.new(heading_id: 'series-1', heading: 'Correspondence', level: 3)) do |component|
        component.with_body { 'Some content' }
      end
      expect(page).to have_css('details.fa-guide__details--subseries summary h5#series-1', text: 'Correspondence',
                                                                                           visible: :all)
    end

    it 'shows the request-count span only when requestable is true' do
      render_inline(described_class.new(heading_id: 'h1', heading: 'x', requestable: true)) do |component|
        component.with_body { 'content' }
      end

      expect(page).to have_css('span.fa-visit__section-count', visible: :all)
    end

    it 'omits the request-count span when requestable is false' do
      render_inline(described_class.new(heading_id: 'h1', heading: 'x', requestable: false)) do |component|
        component.with_body { 'content' }
      end
      expect(page).to have_no_css('span.fa-visit__section-count')
    end
  end
end
