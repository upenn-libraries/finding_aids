# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DetailsComponent, type: :component do
  let(:component) { described_class.new(header_id: 'test-id', header: 'Test', header_tag: :h4) }

  context 'without a body slot' do
    before { render_inline component }

    it 'does not render without a body' do
      expect(page).not_to have_css('details')
      expect(component.render?).to be false
    end
  end

  context 'with a body slot' do
    let(:body) { 'Body' }

    before { render_inline component.with_body_content(body) }

    it 'renders the header with the given markup' do
      expect(page).to have_css('details summary h4', text: 'Test')
    end

    it 'renders the body' do
      expect(page).to have_css('details div', visible: false, text: 'Body')
    end
  end
end
