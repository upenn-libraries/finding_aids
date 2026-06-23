# frozen_string_literal: true

require 'rails_helper'

describe RepositoryQueries do
  let(:solr) { SolrService.new }

  describe '.facet_counts' do
    let(:alpha) do
      attributes_for(:solr_document, repository_ssi: 'Test Repo Alpha')
    end
    let(:documents) do
      [alpha,
       attributes_for(:solr_document, repository_ssi: 'Test Repo Beta'),
       attributes_for(:solr_document, repository_ssi: 'Test Repo Beta')]
    end

    before do
      solr.add_many documents: documents
      solr.commit
    end

    after do
      solr.delete_by_ids documents.pluck(:id)
      solr.commit
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

    it 'does not include repositories with zero documents' do
      results = described_class.facet_counts

      expect(results.map { |r| r[:name] }).not_to include('Non Existent Repo')
    end
  end

  describe '.addresses' do
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

    before do
      solr.add_many documents: documents
      solr.commit
    end

    after do
      solr.delete_by_ids documents.pluck(:id)
      solr.commit
    end

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
