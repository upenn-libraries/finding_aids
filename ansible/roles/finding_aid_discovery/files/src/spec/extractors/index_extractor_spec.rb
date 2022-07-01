# frozen_string_literal: true

require 'rails_helper'

describe IndexExtractor do
  let(:endpoint) { build :endpoint, :index_harvest }
  let(:html) { file_fixture('xml_listing.html').read }
  let(:extractor) { described_class.new(endpoint:) }

  describe '#files' do
    subject(:files) { extractor.files }

    before do
      stub_request(:get, endpoint.url).to_return(body: html)
    end

    it 'responds to enumerable methods' do
      expect(files).to respond_to :each, :each_slice, :map, :first
    end

    it 'returns accurate count from test file' do
      expect(files.count).to eq 5
    end

    it 'returns an Array of XMLFiles' do
      expect(files.first).to be_an_instance_of IndexExtractor::XMLFile
    end

    it 'returns XMLFile objects with properly derived source IDs' do
      expect(
        files.map(&:source_id)
      ).to match_array %w[OM_D767.xml OM_E467_S53.xml OM_LMOR.xml OM_PN2277.xml PS2043__A44.xml]
    end

    context 'when URL raises a 404' do
      before do
        stub_request(:get, endpoint.url).to_return(status: ['404', 'Not Found'])
      end

      it 'raises an OpenURI::HTTPError' do
        expect { files }.to raise_error OpenURI::HTTPError
      end
    end
  end
end
