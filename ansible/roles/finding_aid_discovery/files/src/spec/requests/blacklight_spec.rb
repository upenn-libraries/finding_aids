# frozen_string_literal: true

describe 'Blacklight' do
  it 'loads the homepage with no solr query or results' do
    get '/'
    expect(response.body).to include 'PAARP'
  end

  it 'performs a Solr query if a q param is present' do
    get '/?q=cheese'
    expect(response.body).to include 'No results found for your search'
  end

  context 'with a record in the index' do
    let(:solr) { SolrService.new }
    let(:document_hash) { FactoryBot.attributes_for :solr_document }
    before do
      solr.add_many documents: [document_hash]
      solr.commit
    end

    it 'shows the record in results with a title search' do
      get "/?q=#{document_hash[:title_tsi]}"
      expect(response.body).to include document_hash[:title_tsi]
    end

    xit 'shows the record in results with an identifier search' do
      get "/?q=#{document_hash[:unit_id_ssi]}"
      expect(response.body).to include document_hash[:title_tsi]
    end

    xit 'shows the record in results with an search of some text in a <c> node' do
      get "/?q=#{document_hash[:unit_id_ssi]}"
      expect(response.body).to include document_hash[:title_tsi]
    end

    after do
      solr.delete_by_endpoint 'test-endpoint'
    end
  end
end
