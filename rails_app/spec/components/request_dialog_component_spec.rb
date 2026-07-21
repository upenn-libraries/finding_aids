# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestDialogComponent, type: :component do
  let(:repository) { 'University of Pennsylvania: Kislak Center for Special Collections, Rare Books and Manuscripts' }
  let(:aeon_url) { 'https://aeon.library.upenn.edu' }

  before { render_inline(described_class.new(repository: repository, aeon_url: aeon_url)) }

  it 'renders the modal dialog' do
    expect(page).to have_css('dialog.fa-visit__dialog', visible: :all)
  end

  it 'renders the four step sections' do
    expect(page).to have_css('section[data-request-target="reviewSection"]', visible: :all)
    expect(page).to have_css('section[data-request-target="detailsSection"]', visible: :all)
    expect(page).to have_css('section[data-request-target="authSection"]', visible: :all)
    expect(page).to have_css('section[data-request-target="confirmSection"]', visible: :all)
  end

  it 'hides all but the review section by default' do
    expect(page).to have_css('section[data-request-target="reviewSection"]:not([hidden])', visible: :all)
    expect(page).to have_css('section[data-request-target="detailsSection"][hidden]', visible: :all)
    expect(page).to have_css('section[data-request-target="authSection"][hidden]', visible: :all)
    expect(page).to have_css('section[data-request-target="confirmSection"][hidden]', visible: :all)
  end

  it 'shows the holding institution under "Held at"' do
    expect(page).to have_css('p', text: 'Held at', visible: :all)
    expect(page).to have_css('p', text: repository, visible: :all)
  end

  it 'links the auth step to the Aeon login URL' do
    expect(page).to have_css(
      'a.pl-button.pl-button--accent[@href="' + aeon_url + '"]',
      text: 'Log in to your Research Account', visible: :all
    )
  end

  it 'renders the fixed bottom bar' do
    expect(page).to have_css('.fa-visit__bar[hidden]', visible: :all)
    expect(page).to have_css('button[data-action="click->request#openCopy"]', text: 'Request copies', visible: :all)
    expect(page).to have_css('button[data-action="click->request#openVisit"]', text: 'Plan a visit', visible: :all)
  end

  it 'wires dialog actions to the request controller' do
    expect(page).to have_css('button[data-action="click->request#close"]', visible: :all)
    expect(page).to have_css('button[data-action="click->request#clearAll"]', visible: :all)
    expect(page).to have_css('button[data-action="click->request#goDetails"]', visible: :all)
    expect(page).to have_css('button[data-action="click->request#goReview"]', visible: :all)
    expect(page).to have_css('button[data-action="click->request#place"]', visible: :all)
  end

  it 'submits the details form via the controller' do
    expect(page).to have_css('form[data-action="submit->request#submitDetails"]', visible: :all)
  end

  it 'toggles login confirmation via the controller' do
    expect(page).to have_css('input[data-action="change->request#toggleLogin"]', visible: :all)
  end

  it 'includes the visit-only date field' do
    expect(page).to have_css('input[type="date"][data-request-target="dateInput"][required]', visible: :all)
  end
end
