# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionAccordionComponent, type: :component do
  let(:document) { SolrDocument.new(attributes_for(:solr_document, :with_collection_data)) }
  let(:presenter) { Catalog::ShowDocumentPresenter.new(document, view_context, CatalogController.new.blacklight_config) }
  let(:component) { described_class.new(document: document, presenter: presenter, id: 'description-accordion') }
  let(:view_context) { vc_test_controller.view_context }

  before do
    allow(view_context).to receive_messages({ should_render_field?: true })
  end

  describe '#description_sections' do
    it 'delegates to the document' do
      expect(component.description_sections).to eq(document.description_sections)
    end
  end

  describe 'rendering' do
    before { render_inline component }

    it 'wraps everything in an accordion with the given id' do
      expect(page).to have_css('pennlibs-accordion#description-accordion')
    end

    it 'renders description section details' do
      expect(page).to have_css('pennlibs-accordion details summary h3#bioghist', text: I18n.t('sections.bioghist'))
      expect(page).to have_css('pennlibs-accordion details div', visible: false,
                                                                 text: /This committee was established in/)
    end

    it 'renders rights and citation details' do
      expect(page).to have_css('pennlibs-accordion details div dl dt', visible: false, text: 'Preferred Citation')
      expect(page).to have_css('pennlibs-accordion details div dl dd', visible: false, text: 'Test citation')
    end

    it 'renders a Subject and headings details' do
      expect(page).to have_css('pennlibs-accordion div dl dt', visible: false, text: 'Subject')
      expect(page).to have_css('pennlibs-accordion details div dl dd', visible: false, text: 'Testing')
    end

    context 'when a description section has no content' do
      it 'omits the details element for that section' do
        expect(page).not_to have_css('summary h3#custodhist')
      end
    end
  end
end
