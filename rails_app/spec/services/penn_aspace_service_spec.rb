# frozen_string_literal: true

require 'rails_helper'

describe PennAspaceService do
  subject(:service) { described_class.new repository_id }

  let(:repository_id) { 1 }
  let(:response_headers) { { 'Content-Type': 'application/json' } }

  before do
    stub_request(:post, %r{https://upennapi.as.atlas-sys.com/users/[a-z_]*/login?})
      .to_return(status: 200, body: { session: '1234' }.to_json, headers: response_headers)
    allow(DockerSecrets).to receive(:lookup).with(:penn_aspace_api_username)
                                            .and_return('test_user')
    allow(DockerSecrets).to receive(:lookup).with(:penn_aspace_api_password)
                                            .and_return('test_pass')
  end

  describe '#all_resource_ids' do
    let(:page_one_response) do
      { first_page: 1, last_page: 1, this_page: 1, total: 3, results: [
        { title: 'Published Record 1', publish: true, uri: '/repositories/1/resources/1' },
        { title: 'Published Record 2', publish: true, uri: '/repositories/1/resources/2' },
        { title: 'Unpublished Record', publish: false, uri: '/repositories/1/resources/3' }
      ] }
    end
    let(:page_two_response) do
      { first_page: 1, last_page: 1, this_page: 2, total: 3, results: [] }
    end

    before do
      stub_request(:get, 'https://upennapi.as.atlas-sys.com/repositories/1/resources?page=1')
        .to_return(status: 200, body: page_one_response.to_json, headers: response_headers)
      stub_request(:get, 'https://upennapi.as.atlas-sys.com/repositories/1/resources?page=2')
        .to_return(status: 200, body: page_two_response.to_json, headers: response_headers)
    end

    it 'returns an array of ids' do
      expect(service.all_resource_ids).to match_array %w[1 2]
    end

    it 'only includes IDs for published resources' do
      expect(service.all_resource_ids).not_to include '3'
    end
  end

  describe '#resource_ead_xml' do
    let(:some_content) { '<?xml version="1.0" encoding="utf-8"?><ead></ead>' }

    before do
      stub_request(:get, 'https://upennapi.as.atlas-sys.com/repositories/1/resource_descriptions/1.xml?include_daos=true&include_unpublished=false')
        .to_return(status: 200, body: some_content, headers: { 'Content-Type': 'application/xml' })
    end

    it 'returns XML' do
      expect(service.resource_ead_xml('1')).to include some_content
    end
  end
end
