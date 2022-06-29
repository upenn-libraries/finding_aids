# frozen_string_literal: true

# Extract XML content from Penn ArchivesSpace
class PennArchivesSpaceExtractor < BaseExtractor
  WEB_URL_PRODUCTION = 'https://upennstaff.as.atlas-sys.com'

  attr_reader :endpoint

  # @param [Endpoint] endpoint
  # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
  def initialize(endpoint:, api: nil)
    @api = api || ArchivesSpaceApi.new(endpoint.harvest_config['repository_id'])
    super endpoint:
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files ||= build_archivesspace_files
  end

  # Pretend the API is like a file
  class PennArchivesSpaceFile < BaseEadSource
    # @param [String] id
    # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
    def initialize(id:, api:)
      super id: id
      @api = api
    end

    # return XML content
    # @return [String]
    def xml
      @api.resource_ead_xml(id)
    end
  end

  # simple wrapper for the gem-provided ASpace API
  class ArchivesSpaceApi
    # @param [String] repository_id
    def initialize(repository_id)
      client.repository(repository_id)
    end

    # @return [Array]
    def all_resource_ids
      response = client.get('resources', query: { include_unpublished: false, all_ids: true })
      raise StandardError, "Bad response from ASpace API: #{response.body}" unless response.status_code == 200

      response.parsed
    end

    # @param [String] resource_id
    # @return [String]
    def resource_ead_xml(resource_id)
      client.get("resource_descriptions/#{resource_id}.xml").body
    end

    private

    def client
      @client ||= ArchivesSpace::Client.new(config).login
    end

    def config
      ArchivesSpace::Configuration.new(
        {
          base_uri: 'https://upennapi.as.atlas-sys.com',
          base_repo: '',
          username: SecretsService.lookup(key: 'penn_aspace_api_username'),
          password: SecretsService.lookup(key: 'penn_aspace_api_password'),
          page_size: 50, throttle: 0,
          debug: false, verify_ssl: false
        }
      )
    end
  end

  private

  def build_archivesspace_files
    @api.all_resource_ids.map do |resource_id|
      PennArchivesSpaceFile.new(id: resource_id, api: @api)
    end
  end
end
