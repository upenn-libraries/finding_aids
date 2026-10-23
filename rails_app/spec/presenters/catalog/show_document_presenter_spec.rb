# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::ShowDocumentPresenter do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.add_show_field :repository, group: :overview
      config.add_show_field :email, group: :contact
    end
  end
  let(:view_context) { CatalogController.new.view_context }
  let(:doc) { SolrDocument.new({ repository: 'archives', address: 'somewhere' }) }
  let(:presenter) { described_class.new(doc, view_context, blacklight_config) }

  describe '#field_presenters_by_group' do
    it 'returns only the field presenters belonging to the requested group' do
      field_presenters = presenter.field_presenters_by_group(:overview).to_a
      expect(field_presenters.size).to eq 1
      expect(field_presenters.first.key).to eq 'repository'
    end

    it 'returns no field presenters when no fields match the requested group' do
      field_presenters = presenter.field_presenters_by_group(:nonexistent_group).to_a
      expect(field_presenters).to be_empty
    end
  end
end
