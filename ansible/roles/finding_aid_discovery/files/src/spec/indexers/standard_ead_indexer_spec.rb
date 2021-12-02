require 'rails_helper'

describe StandardEadIndexer do
  let(:filename) { 'ead/ead1.xml' }
  let(:endpoint) { FactoryBot.build :endpoint, :index_harvest }
  let(:ead_xml) { Nokogiri::XML.parse file_fixture(filename).read }
  let(:indexer) { described_class.new filename, endpoint }

  context 'attribute extraction methods' do
    it 'has an ID' do
      expect(indexer.id).to eq "#{endpoint.slug}_#{filename}"
    end
  end

  context 'as hash' do
    let(:hash) { indexer.process(ead_xml) }
    it 'returns a hash' do
      expect(hash).to be_a_kind_of Hash
    end
  end
end
