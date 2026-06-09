# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeaderComponent, type: :component do
  subject(:component) { page }

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:user) { nil }

  before do
    render_inline(described_class.new(blacklight_config: blacklight_config, user: user))
  end

  it 'renders the pennlibs-header web component' do
    expect(component).to have_css 'pennlibs-header'
  end

  it 'renders the search bar' do
    expect(component).to have_css 'div.navbar-search'
  end

  it 'renders the search input' do
    expect(component).to have_field 'q'
  end

  context 'when logged in' do
    let(:user) { instance_double(User) }

    it 'shows the sign out button' do
      expect(component).to have_button I18n.t('header.sign_out')
    end
  end
end
