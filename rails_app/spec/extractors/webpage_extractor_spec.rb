# frozen_string_literal: true

require 'rails_helper'

describe WebpageExtractor do
  let(:endpoint) { build(:endpoint, :webpage_harvest) }
  let(:html) { file_fixture('xml_listing.html').read }
  let(:extractor) { described_class.new(endpoint: endpoint) }

  describe '#files' do
    subject(:files) { extractor.files }

    let(:urls) do
      %w[
        https://www.geocities.com/OM_D767.xml
        https://www.test.com/pacscl/OM_E467_S53.xml?query=pram
        https://www.test.com/pacscl/OM_LMOR.xml
        https://www.test.com/pacscl/OM_PN2277.xml?query=param#anchor
        https://www.test.com/pacscl/PS2043__A44.xml
      ]
    end

    context 'when URL is retrieved successfully' do
      before do
        stub_request(:get, endpoint.webpage_url).to_return(body: html)
      end

      it 'responds to enumerable methods' do
        expect(files).to respond_to :each, :each_slice, :map, :first
      end

      it 'returns accurate count from test file' do
        expect(files.count).to eq 5
      end

      it 'returns an Array of XMLFiles' do
        expect(files.first).to be_an_instance_of WebpageExtractor::XMLFile
      end

      it 'returns XMLFile objects with properly derived source IDs' do
        expect(
          files.map(&:source_id)
        ).to match_array %w[OM_D767.xml OM_E467_S53.xml OM_LMOR.xml OM_PN2277.xml PS2043__A44.xml]
      end

      it 'returns XMLFile objects with properly derived URLs' do
        expect(files.map(&:url)).to match_array(urls)
      end
    end

    context 'when URL is redirected' do
      let(:redirected_to) { 'https://www.example.com/pacscl/' }
      let(:urls) do
        %w[
          https://www.geocities.com/OM_D767.xml
          https://www.example.com/pacscl/OM_E467_S53.xml?query=pram
          https://www.example.com/pacscl/OM_LMOR.xml
          https://www.example.com/pacscl/OM_PN2277.xml?query=param#anchor
          https://www.example.com/pacscl/PS2043__A44.xml
        ]
      end

      before do
        stub_request(:get, endpoint.webpage_url).to_return(status: 302, headers: { 'Location' => redirected_to })
        stub_request(:get, redirected_to).to_return(body: html)
      end

      it 'returns XMLFiles objects with URLs with the proper base uri' do
        expect(files.map(&:url)).to match_array(urls)
      end
    end

    context 'when URL raises a 404' do
      before do
        stub_request(:get, endpoint.webpage_url).to_return(status: ['404', 'Not Found'])
      end

      it 'raises an OpenURI::HTTPError' do
        expect { files }.to raise_error OpenURI::HTTPError
      end
    end
  end
end
