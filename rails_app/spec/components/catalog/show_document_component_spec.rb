# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::ShowDocumentComponent, type: :component do
  let(:document) { SolrDocument.new(attributes_for(:solr_document, :with_collection_data)) }
  let(:presenter) { Catalog::ShowDocumentPresenter.new(document, view_context, CatalogController.new.blacklight_config) }
  let(:component) { described_class.new(document: presenter) }
  let(:view_context) { vc_test_controller.view_context }

  before do
    with_controller_class(CatalogController) do
      vc_test_controller.request.path_parameters[:controller] = 'catalog'
      allow(view_context).to receive_messages({ should_render_field?: true })
      render_inline(component)
    end
  end

  describe 'rendering the header intro' do
    it 'shows the collection title in an expand-text control' do
      expect(page).to have_css('.fa-guide-header__intro h1#guide-title pennlibs-expand-text',
                               text: presenter.heading)
    end

    it 'shows the abstract in an expand-text control' do
      expect(page).to have_css('.fa-guide-header__intro p pennlibs-expand-text',
                               text: document.fetch(:abstract_scope_contents_tsi))
    end
  end

  describe 'rendering the header aside' do
    it 'links to a repository facet search' do
      link = view_context.search_catalog_path({ "f[repository_ssi][]": document.fetch(:repository_ssi),
                                                only_path: true })
      expect(page).to have_css("aside.fa-guide-header__institution p a[href='#{link}']")
    end

    it 'links to the contact section' do
      expect(page).to have_css("aside.fa-guide-header__institution a.pl-button--accent[href='#contact']",
                               text: I18n.t('show.aside.contact'))
    end
  end

  describe 'rendering the header metadata strip' do
    it 'shows creator' do
      expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dt', text: I18n.t('fields.creators'))
      document.fetch(:creators_ssim).each do |creator|
        expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dd', text: creator)
      end
    end

    it 'shows date' do
      expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dt', text: I18n.t('fields.date'))
      document.display_dates.each do |date|
        expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dd', text: date)
      end
    end

    it 'shows extent' do
      expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dt', text: I18n.t('fields.extent'))
      document.fetch(:extent_ssim).each do |extent|
        expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dd', text: extent)
      end
    end

    it 'shows the call number' do
      expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dt',
                               text: I18n.t('fields.pretty_unit_id'))
      expect(page).to have_css('.fa-guide-header__strip dl.fa-metadata div dd',
                               text: document.fetch(:pretty_unit_id_ss))
    end
  end

  describe 'rendering the table of contents' do
    it 'renders a table of contents navigation', pending: 'not implemented' do
      expect(page).to have_css("div.fa-guide-layout nav.fa-toc[aria-label='Table of contents'] ul li",
                               text: presenter.heading)
    end
  end

  describe 'rendering the description sections' do
    it 'renders the description section heading and guide text' do
      expect(page).to have_css('div#description-sections div.fa-section-header h2#description',
                               text: I18n.t('show.sections.description.header'))
      expect(page).to have_css('div#description-sections div.fa-section-header p',
                               text: I18n.t('show.sections.description.guide'))
    end

    it 'renders an expand/collapse toggle button for the description accordion' do
      expect(page).to have_css("div#description-sections button[data-pl-accordion-toggle='description-accordion']")
    end

    it 'renders the description accordion component' do
      expect(page).to have_css('div#description-sections pennlibs-accordion#description-accordion')
    end
  end

  describe 'rendering the inventory sections' do
    it 'renders the inventory section heading and guide text' do
      expect(page).to have_css('div#inventory-sections div.fa-section-header h2#inventory',
                               text: I18n.t('show.sections.inventory.header'))
      expect(page).to have_css('div#inventory-sections div.fa-section-header p',
                               text: I18n.t('show.sections.inventory.guide'))
    end

    it 'renders an expand/collapse toggle button for the inventory accordion' do
      expect(page).to have_css("div#inventory-sections button[data-pl-accordion-toggle='inventory-accordion']")
    end

    it 'renders the inventory accordion component' do
      expect(page).to have_css('div#inventory-sections pennlibs-accordion#inventory-accordion')
    end

    it 'renders inventory details' do
      expect(page).to have_css('pennlibs-accordion#inventory-accordion details summary h3#series-1',
                               text: 'Test Collection')
    end
  end

  describe 'rendering the contact section' do
    it 'renders the contact section heading' do
      expect(page).to have_css('div.fa-guide-content section h2#contact',
                               text: I18n.t('show.sections.contact.header'))
    end

    it "includes the document's repository in the contact guide text" do
      expect(page).to have_css('div.fa-guide-content section p.pl-line-length.pl-margin-b-m',
                               text: /These materials are held by #{document.repository}/)
    end

    it 'shows repository address' do
      expect(page).to have_css('div.fa-guide-content section dl.pl-dl dt',
                               text: I18n.t('fields.repository_address'))
      expect(page).to have_css('div.fa-guide-content section dl.pl-dl dd', text: document.repository_address)
    end

    it 'shows first contact email' do
      expect(page).to have_css('div.fa-guide-content section dl.pl-dl dt', text: I18n.t('fields.contact_email'))
      expect(page).to have_css("div.fa-guide-content section dl.pl-dl dd a[href='mailto:#{document.contact_email}']",
                               text: document.contact_email)
    end

    it 'shows repository website' do
      expect(page).to have_css('div.fa-guide-content section dl.pl-dl dt', text: I18n.t('fields.url'))
      expect(page).to have_css("div.fa-guide-content section dl.pl-dl dd a[href='#{document.fetch(:link_url_ss)}']",
                               text: document.fetch(:link_url_ss))
    end
  end
end
