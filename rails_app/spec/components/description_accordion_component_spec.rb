# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionAccordionComponent, type: :component do
  let(:document) { SolrDocument.new(attributes_for(:solr_document, :with_collection_data)) }
  let(:presenter) { Catalog::ShowDocumentPresenter.new(document, view_context, CatalogController.new.blacklight_config) }
  let(:component) { described_class.new(document: document, presenter: presenter, id: 'description-accordion') }
  let(:view_context) { vc_test_controller.view_context }

  before { allow(view_context).to receive_messages({ should_render_field?: true }) }

  describe 'rendering' do
    it 'wraps everything in an accordion with the given id' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion#description-accordion')
    end

    it 'renders description section details' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion details summary h3#bioghist', text: I18n.t('sections.bioghist'))
      expect(page).to have_css('pennlibs-accordion details div', visible: false,
                                                                 text: /This committee was established in/)
    end

    it 'renders rights and citation details' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion details summary h3#rights',
                               text: I18n.t('sections.rights_and_citation'))
    end

    it 'renders rights and citation data using a description list' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion details div dl dt', visible: false, text: 'Preferred Citation')
      expect(page).to have_css('pennlibs-accordion details div dl dd', visible: false, text: 'Test citation')
    end

    it 'renders subjects and headings details' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion details summary h3#topics',
                               text: I18n.t('sections.subjects_and_headings'))
    end

    it 'renders a subject and headings data using a description list' do
      render_inline component
      expect(page).to have_css('pennlibs-accordion div dl dt', visible: false, text: 'Subject')
      expect(page).to have_css('pennlibs-accordion details div dl dd', visible: false, text: 'Testing')
    end

    context 'with missing details' do
      before { allow(presenter).to receive(:field_presenters_by_group).and_return([]) }

      it 'omits the missing description sections' do
        render_inline component
        expect(page).not_to have_css('summary h3#custodhist')
      end

      it 'omits the rights and citation details' do
        render_inline component
        expect(page).not_to have_css('summary h3#rights')
      end

      it 'omits subjects and headings details' do
        render_inline component
        expect(page).not_to have_css('summary h3#topics')
      end
    end
  end
end
