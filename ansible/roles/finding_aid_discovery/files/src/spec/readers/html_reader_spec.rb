require 'rails_helper'

describe HtmlReader do
  let(:url) { 'http://www.example.com/eads/' }
  let(:html) { file_fixture('xml_listing.html').read }

  before do
    stub_request(:get, url).to_return(body: html)
  end

  context '#extract' do
    let(:reader) { HtmlReader.new(url: url) }

    it 'returns correct list of links' do
      expect(reader.extract).to be_an_instance_of Array
    end
  end
end
