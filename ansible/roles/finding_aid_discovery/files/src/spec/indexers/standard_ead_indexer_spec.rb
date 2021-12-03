require 'rails_helper'

describe StandardEadIndexer do
  let(:endpoint) { FactoryBot.build :endpoint, :index_harvest }
  let(:url) { "#{endpoint.url}ead/ead1.xml" }
  let(:indexer) { described_class.new url, endpoint }

  # TODO: test handling of error case exceptions (HTTP, Nokogiri parsing)

  context 'sample file 1' do
    before do
      stub_request(:get, url).to_return(body: file_fixture('ead/ead1.xml'))
    end

    context 'attribute extraction methods' do
      it 'has an ID' do
        expect(indexer.id).to eq "#{endpoint.slug}_ead/ead1.xml"
      end
    end

    context 'as hash' do
      let(:hash) { indexer.process }
      it 'returns a hash' do
        expect(hash).to be_a_kind_of Hash
      end
    end
  end
end
