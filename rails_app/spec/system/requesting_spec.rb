# frozen_string_literal: true

require 'system_helper'

RSpec.describe 'Catalog Show page requesting behavior' do
  include EadHelpers
  include Turbo::SystemTestHelper

  let(:document) { attributes_for(:solr_document, :requestable, xml_ss: xml) }
  let(:container_title) { 'Series One' }
  let(:xml) do
    <<~XML
      <ead>
        <archdesc level="collection">
            <did></did>
            <dsc>
              <c level="series"><did><unittitle>#{container_title}</unittitle></did></c>
            </dsc>
        </archdesc>
      </ead>
    XML
  end

  before do
    seed_solr([document])
    visit solr_document_path(document[:id])
  end

  after { cleanup_solr([document]) }

  it 'shows hidden request bar and modal content' do
    expect(page).to have_css('.fa-request__bar', visible: :hidden)
    expect(page).to have_css('.fa-request__dialog', visible: :hidden)
  end

  describe 'requesting panel toggle' do
    before do
      within('#inventory-sections') do
        click_button I18n.t('show.buttons.accordion_control.expand')
      end
    end

    it 'shows the requesting bottom panel if a container is selected' do
      check container_title
      expect(page).to have_css('.fa-request__bar', visible: :visible)
    end

    it 'hides the requesting bottom panel when no containers remain selected' do
      check container_title
      expect(page).to have_css('.fa-request__bar', visible: :visible)
      uncheck container_title
      expect(page).to have_css('.fa-request__bar', visible: :hidden)
    end
  end
end
