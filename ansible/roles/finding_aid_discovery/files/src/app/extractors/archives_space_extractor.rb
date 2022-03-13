# frozen_string_literal: true

# Extract XML content from ArchivesSpace
class ArchivesSpaceExtractor
  attr_reader :endpoint

  # @param [Endpoint] endpoint
  # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
  def initialize(endpoint: nil, api: api_client)
    @endpoint = endpoint
    @api = api
    set_repository
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files ||= build_as_files
  end

  # Pretend the API is like a file
  class ArchivesSpaceFile
    # @param [Endpoint] endpoint
    # @param [String] resource_id
    # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
    def initialize(resource_id:, endpoint:, api:)
      @resource_id = resource_id
      @endpoint = endpoint
      @api = api
    end

    # return something like a URL for use in the
    # @return [String]
    def url
      @resource_id
    end

    # return XML content
    # @return [String]
    def read
      @api.client.get("resource_descriptions/#{@resource_id}.xml").body
    end
  end

  private

  # @return [ArchivesSpace::Client]
  def api_client
    ArchivesSpace::Client.new(config).login
  end

  def set_repository
    @api.client.repository(endpoint.harvest_config['repository_id'])
  end

  def build_as_files
    resources = @api.client.get('resources', query: { include_unpublished: false, all_ids: true }).parsed
    resources.map do |resource_id|
      ArchivesSpaceFile.new(resource_id: resource_id, endpoint: endpoint, api: @api)
    end
  end

  # @return [ArchivesSpace::Configuration]
  # TODO: how about some potential non-Penn ASpace instance?
  def api_config
    ArchivesSpace::Configuration.new(
      {
        base_uri: 'https://upennsbapi.as.atlas-sys.com',
        base_repo: '',
        username: ENV.fetch('ASPACE_API_USERNAME'),
        password: ENV.fetch('ASPACE_API_PASSWORD'),
        page_size: 50, throttle: 0,
        debug: false, verify_ssl: false
      }
    )
  end
end
