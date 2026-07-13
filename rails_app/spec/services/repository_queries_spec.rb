# frozen_string_literal: true

require 'rails_helper'

describe RepositoryQueries do
  let(:solr) { SolrService.new }

  shared_context 'with solr documents' do
    before do
      solr.add_many documents: documents
      solr.commit
    end

    after do
      solr.delete_by_ids documents.pluck(:id)
      solr.commit
    end
  end

  describe '.titles_by_repository' do
    include_context 'with solr documents'

    let(:documents) do
      [
        attributes_for(:solr_document, repository_ssi: 'Repo A', title_tsi: 'Guide One'),
        attributes_for(:solr_document, repository_ssi: 'Repo A', title_tsi: 'Guide Two'),
        attributes_for(:solr_document, repository_ssi: 'Repo B', title_tsi: 'Guide Three')
      ]
    end

    it 'groups titles by repository, sorted alphabetically' do
      results = described_class.titles_by_repository

      expect(results['Repo A']).to eq(['Guide One', 'Guide Two'])
      expect(results['Repo B']).to eq(['Guide Three'])
    end
  end
end
