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

  describe '.facet_counts' do
    before { seed_solr(documents) }
    after  { cleanup_solr(documents) }

    let(:demo_repo) do
      attributes_for(:solr_document, repository_ssi: 'Test Repo Alpha')
    end
    let(:documents) do
      [demo_repo,
       attributes_for(:solr_document, repository_ssi: 'Test Repo Beta'),
       attributes_for(:solr_document, repository_ssi: 'Test Repo Beta')]
    end

    it 'returns an array of name/count hashes' do
      results = described_class.facet_counts
      ours = results.select { |r| r[:name].start_with?('Test Repo') }

      expect(ours).to all(include(:name, :count))
    end

    it 'returns live counts from the index' do
      results = described_class.facet_counts

      alpha = results.find { |r| r[:name] == 'Test Repo Alpha' }
      beta = results.find { |r| r[:name] == 'Test Repo Beta' }

      expect(alpha[:count]).to eq(1)
      expect(beta[:count]).to eq(2)
    end

    it 'sorts by count descending across all results' do
      results = described_class.facet_counts

      expect(results.first[:count]).to be >= results.last[:count]
    end
  end

  describe '.addresses' do
    before { seed_solr(documents) }
    after  { cleanup_solr(documents) }

    let(:with_address) do
      attributes_for(:solr_document,
                     repository_ssi: 'Test Repo With Address',
                     repository_address_ssi: '123 Main St, Philadelphia, PA 19104')
    end
    let(:without_address) do
      attributes_for(:solr_document,
                     repository_ssi: 'Test Repo Without Address',
                     repository_address_ssi: nil)
    end
    let(:documents) { [with_address, without_address] }

    it 'returns a name-to-address hash' do
      results = described_class.addresses

      expect(results).to be_a(Hash)
      expect(results['Test Repo With Address'])
        .to eq('123 Main St, Philadelphia, PA 19104')
    end

    it 'includes repositories that have addresses' do
      results = described_class.addresses

      expect(results).to have_key('Test Repo With Address')
    end

    it 'excludes repositories without addresses' do
      results = described_class.addresses

      expect(results).not_to have_key('Test Repo Without Address')
    end
  end
end
