# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FooterComponent, type: :component do
  subject(:component) { page }

  before do
    render_inline(described_class.new(user: user))
  end

  let(:user) { nil }

  it 'renders the pennlibs-footer web component' do
    expect(component).to have_css 'pennlibs-footer'
  end

  it 'renders the pennlibs-feedback web component' do
    expect(component).to have_css 'pennlibs-feedback'
  end

  it 'renders the pennlibs-chat web component' do
    expect(component).to have_css 'pennlibs-chat'
  end

  it 'renders navigation links' do
    expect(component).to have_link I18n.t('footer.nav.home')
  end

  it 'renders policy links' do
    expect(component).to have_link I18n.t('footer.organizations.pacscl')
  end

  context 'when not logged in' do
    it 'does not show the admin link' do
      expect(component).to have_no_link I18n.t('footer.nav.admin')
    end
  end

  context 'when logged in' do
    let(:user) { instance_double(User) }

    it 'shows the admin link' do
      expect(component).to have_link I18n.t('footer.nav.admin')
    end
  end
end
