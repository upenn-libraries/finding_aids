# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestingComponent, type: :component do
  subject(:component) { page }

  before do
    render_inline(described_class.new(document: SolrDocument.new(document_attributes)))
  end

  context 'with a requestable document' do
    let(:document_attributes) { attributes_for :solr_document, :requestable }

    it 'includes the request bar element' do
      expect(component).to have_css '.fa-request__bar', visible: :hidden
    end
  end

  context 'with a non-requestable document' do
    let(:document_attributes) { attributes_for :solr_document }

    it 'does not include the request bar element' do
      expect(component).to have_no_css '.fa-request__bar', visible: :hidden
    end
  end
end
