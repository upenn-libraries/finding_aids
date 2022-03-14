# frozen_string_literal: true

# Extract XML content from ArchivesSpace
class ArchivesSpaceExtractor
  attr_reader :endpoint

  # @param [Endpoint] endpoint
  # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
  def initialize(endpoint:, api: api_client)
    @api = api
    super
    set_repository
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files ||= build_as_files
  end

  # Pretend the API is like a file
  class ArchivesSpaceFile < BaseEadFile
    # @param [String] id
    # @param [Endpoint] endpoint
    # @param [ArchivesSpace::Client] api
    def initialize(id:, endpoint:, api:)
      super(id: id, endpoint: endpoint)
      @api = api
    end

    # return XML content
    # @return [String]
    def xml
      @api.client.get("resource_descriptions/#{@id}.xml").body
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
      ArchivesSpaceFile.new(id: resource_id, endpoint: endpoint, api: @api)
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
