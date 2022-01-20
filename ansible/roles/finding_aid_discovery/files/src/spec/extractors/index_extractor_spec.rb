# frozen_string_literal: true

require 'rails_helper'

describe IndexExtractor do
  let(:endpoint) { build :endpoint, :index_harvest }
  let(:html) { file_fixture('xml_listing.html').read }
  let(:extractor) { described_class.new(endpoint) }

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

    it 'returns XMLFile objects with correct urls' do
      expect(files.map(&:url)).to match_array([
                                                'https://www.geocities.com/OM_D767.xml',
                                                'https://www.test.com/pacscl/OM_E467_S53.xml?query=pram',
                                                'https://www.test.com/pacscl/OM_LMOR.xml',
                                                'https://www.test.com/pacscl/OM_PN2277.xml?query=param#anchor',
                                                'https://www.test.com/pacscl/PS2043__A44.xml'
                                              ])
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
