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

  describe 'rendering header' do
    let(:css) { 'div.document-main-section div.fa-guide-header' }

    it 'shows the abstract in the header section' do
      abstract_css =  "#{css} div.fa-guide-header__hero div.fa-guide-header__intro p"
      expect(page).to have_css(abstract_css, text: document.fetch(:abstract_scope_contents_tsi))
    end

    it 'links to a repository facet search in the header aside' do
      repo_css = "#{css} div.fa-guide-header__hero aside.fa-guide-header__institution p"
      link = view_context.search_catalog_path({ "f[repository_ssi][]": document.fetch(:repository_ssi),
                                                only_path: true })
      expect(page).to have_css("#{repo_css} a[href='#{link}']")
    end

    it 'links to the contact section from the header aside' do
      css = "#{css} aside.fa-guide-header__institution a.pl-button.pl-button--accent[href='#contact']"
      expect(page).to have_css(css, text: I18n.t('show.aside.contact'))
    end

    it 'renders the collection title' do
      title_css = "#{css} div.fa-guide-header__hero div.fa-guide-header__intro h1#guide-title"
      expect(page).to have_css(title_css, text: presenter.heading)
    end

    it 'shows the access restrictions in the header aside' do
      access_css = "#{css} div.fa-guide-header__hero aside.fa-guide-header__institution p"
      expect(page).to have_css(access_css, text: document.access_restrictions)
    end

    it 'renders collection overview metadata in the header strip' do
      expect(page).to have_css("#{css} div.fa-guide-header__strip dl.fa-metadata")
    end

    it 'shows creator in the header strip' do
      metadata_css = "#{css} div.fa-guide-header__strip dl.fa-metadata div"
      expect(page).to have_css("#{metadata_css} dt", text: I18n.t('fields.creators'))
      document.fetch(:creators_ssim).each { |creator| expect(page).to have_css("#{metadata_css} dd", text: creator) }
    end

    it 'shows date in the header strip' do
      metadata_css = "#{css} div.fa-guide-header__strip dl.fa-metadata div"
      expect(page).to have_css("#{metadata_css} dt", text: I18n.t('fields.date'))
      document.display_dates.each { |date| expect(page).to have_css("#{metadata_css} dd", text: date) }
    end

    it 'shows extent in the header strip' do
      metadata_css = "#{css} div.fa-guide-header__strip dl.fa-metadata div"
      expect(page).to have_css("#{metadata_css} dt", text: I18n.t('fields.extent'))
      document.fetch(:extent_ssim).each { |extent| expect(page).to have_css("#{metadata_css} dd", text: extent) }
    end

    it 'shows the call number in the header strip' do
      metadata_css = "#{css} div.fa-guide-header__strip dl.fa-metadata div"
      expect(page).to have_css("#{metadata_css} dt", text: I18n.t('fields.pretty_unit_id'))
      expect(page).to have_css("#{metadata_css} dd", text: document.fetch(:pretty_unit_id_ss))
    end
  end

  describe 'rendering table of contents' do
    let(:css) { 'div.document-main-section div.fa-guide-layout' }

    it 'renders a table of contents navigation', pending: 'not implemented' do
      expect(page).to have_css("#{css} nav.fa-toc[aria-label='Table of contents'] ul li", text: presenter.heading)
    end
  end

  describe 'rendering description' do
    let(:css) { 'div.document-main-section div.fa-guide-layout div#description-sections' }

    it 'renders the description section heading and guide text' do
      section_css = "#{css} div.fa-section-header"

      expect(page).to have_css("#{section_css} h2#description", text: I18n.t('show.sections.description.header'))
      expect(page).to have_css("#{section_css} p", text: I18n.t('show.sections.description.guide'))
    end

    it 'renders an expand/collapse toggle button for the description accordion' do
      expect(page).to have_css("#{css} button[data-pl-accordion-toggle='description-accordion']")
    end

    it 'renders the description accordion component' do
      expect(page).to have_css("#{css} pennlibs-accordion#description-accordion")
    end
  end

  describe 'rendering inventory' do
    let(:css) { 'div.document-main-section div.fa-guide-layout div#inventory-sections' }

    it 'renders the inventory section heading and guide text' do
      section_css = 'div.fa-section-header'
      expect(page).to have_css("#{section_css} h2#inventory", text: I18n.t('show.sections.inventory.header'))
      expect(page).to have_css("#{section_css} p", text: I18n.t('show.sections.inventory.guide'))
    end

    it 'renders an expand/collapse toggle button for the inventory accordion' do
      expect(page).to have_css("#{css} button[data-pl-accordion-toggle='inventory-accordion']")
    end

    it 'renders the description accordion component' do
      expect(page).to have_css("#{css} pennlibs-accordion#inventory-accordion")
    end

    it 'renders inventory details' do
      detail_css = "#{css} pennlibs-accordion#inventory-accordion"
      expect(page).to have_css("#{detail_css} details summary h3#series-1", text: 'Test Collection')
    end
  end

  describe 'rendering contact' do
    let(:css) { 'div.document-main-section div.fa-guide-content section' }

    it 'renders the contact section heading' do
      expect(page).to have_css("#{css} h2#contact", text: I18n.t('show.sections.contact.header'))
    end

    it "includes the document's repository in the contact guide text" do
      expect(page).to have_css("#{css} p.pl-line-length.pl-margin-b-m",
                               text: /These materials are held by #{document.repository}/)
    end

    it 'shows repository address' do
      expect(page).to have_css("#{css} dl.pl-dl dt", text: I18n.t('fields.repository_address'))
      expect(page).to have_css("#{css} dl.pl-dl dd"), document.repository_address
    end

    it 'shows first contact email' do
      expect(page).to have_css("#{css} dl.pl-dl dt", text: I18n.t('fields.contact_email'))
      expect(page).to have_css("#{css} dl.pl-dl dd a[href='mailto:#{document.contact_email}']",
                               text: document.contact_email)
    end

    it 'shows repository website' do
      expect(page).to have_css("#{css} dl.pl-dl dt", text: I18n.t('fields.url'))
      expect(page).to have_css("#{css} dl.pl-dl dd a[href='#{document.fetch(:link_url_ss)}']",
                               text: document.fetch(:link_url_ss))
    end
  end
end
