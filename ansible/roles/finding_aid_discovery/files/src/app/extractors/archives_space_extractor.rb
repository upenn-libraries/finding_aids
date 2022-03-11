# frozen_string_literal: true

# Extract XML content from ArchivesSspace
# Based on how the HarvestingService is built, this class MUST have a #files method that returns an object 
# with #url and #read methods 
# #url is used in generating the record ID
# #read returns the XML content
class ArchivesSpaceExtractor
  attr_reader :endpoint

  # @param [Endpoint] endpoint
  # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
  def initialize(endpoint: nil, api: ArchivesSpaceApi.new)
    @endpoint = endpoint
    @api = api
    set_repository
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files  ||= build_as_files
  end

  private

  def set_repository
    @api.client.repository(endpoint.harvest_config['repository_id'])
  end

  def build_as_files
    resources = @api.client.get('resources', query: { include_unpublished: false, all_ids: true }).parsed
    resources.map do |resource_id|
      byebug
      ArchivesSpaceFile.new(resource_id: resource_id, endpoint: endpoint, api: @api)
    end
  end

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

  class ArchivesSpaceApi
    attr_accessor :client

    def initialize
      @client = ArchivesSpace::Client.new(config).login # TODO: capture errors here?
    end

    private

    # @return [ArchivesSpace::Configuration]
    # TODO: how about some potential non-Penn ASpace instance?
    def config
      ArchivesSpace::Configuration.new({
        base_uri: 'https://upennsbapi.as.atlas-sys.com',
        base_repo: '',
        username: ENV.fetch('ASPACE_API_USERNAME'),
        password: ENV.fetch('ASPACE_API_PASSWORD'),
        page_size: 50,
        throttle: 0,
        debug: true,
        verify_ssl: false
      })
    end
  end
end
