# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Requesting::BarComponent, type: :component do
  subject(:component) { page }

  before do
    render_inline(described_class.new(document: SolrDocument.new(document_attributes),
                                      repository_info: repository_info))
  end

  let(:document_attributes) { attributes_for :solr_document, :requestable }
  let(:repository_info) { { repo_name: 'name' } }

  it 'includes settings in the data attributes of the wrapper div' do
    expect(component).to have_css('[data-request-ere-endpoint]', visible: :hidden)
  end

  it 'includes repository info in the data attributes of the wrapper div' do
    expect(component).to have_css('[data-request-repo-name="name"]', visible: :hidden)
  end

  it 'includes a scan button' do
    expect(component).to have_button I18n.t('show.sections.request.bar.scan.button'), visible: :hidden
  end

  it 'includes a visit button' do
    expect(component).to have_button I18n.t('show.sections.request.bar.visit.button'), visible: :hidden
  end
end
