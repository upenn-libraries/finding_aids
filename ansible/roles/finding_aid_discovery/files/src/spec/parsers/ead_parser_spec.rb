# frozen_string_literal: true

require 'rails_helper'

describe EadParser do
  let(:endpoint) { build :endpoint, :index_harvest }
  let(:url) { "#{endpoint.url}ead/ead1.xml" }
  let(:xml) { file_fixture('ead/ead1.xml') }

  context 'indexing EADs' do
    let(:parser) { described_class.new endpoint }

    context 'sample file 1' do
      context 'as hash' do
        let(:hash) { parser.parse(url, xml) }

        it 'returns a hash' do
          expect(hash).to be_a_kind_of Hash
        end

        it 'has expected value for the id suffix' do
          expect(hash[:id]).to end_with '_ead1'
        end

        it 'has expected value for title_tsim' do
          expect(hash[:title_tsim]).to eq 'Births, death, marriage records within area of Philadelphia Yearly Meeting'
        end
      end
    end
  end
end
