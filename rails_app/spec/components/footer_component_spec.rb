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

  it 'renders navigation links' do
    expect(component).to have_link I18n.t('footer.archives.home')
    expect(component).to have_link I18n.t('footer.archives.about')
  end

  it 'renders the PACSCL link' do
    expect(component).to have_link I18n.t('footer.archives.pacscl')
  end

  it 'renders the harmful language statement link' do
    expect(component).to have_link I18n.t('footer.archives.statement'), href: I18n.t('urls.statement')
  end

  context 'when not logged in' do
    it 'does not show the admin link' do
      expect(component).to have_no_link I18n.t('footer.admin.link')
    end
  end

  context 'when logged in' do
    let(:user) { instance_double(User) }

    it 'shows the admin link' do
      expect(component).to have_link I18n.t('footer.admin.link')
    end
  end
end
