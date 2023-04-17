# frozen_string_literal: true

# Extract XML content from Penn ArchivesSpace
class PennArchivesSpaceExtractor < BaseExtractor
  WEB_URL_PRODUCTION = 'https://upennstaff.as.atlas-sys.com'

  attr_reader :endpoint

  # @param [Endpoint] endpoint
  # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
  def initialize(endpoint:, api: nil)
    @api = api || PennAspaceService.new(endpoint.harvest_config['repository_id'])
    super endpoint: endpoint
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files ||= build_archivesspace_files
  end

  # Pretend the API is like a file
  class PennArchivesSpaceFile < BaseEadSource
    attr_reader :id

    # @param [String] id
    # @param [ArchivesSpaceExtractor::ArchivesSpaceApi] api
    def initialize(id:, api:)
      @id = id
      @api = api
    end

    # return XML content
    # @return [String]
    def xml
      @api.resource_ead_xml(id)
    end

    def source_id
      @id
    end
  end

  private

  def build_archivesspace_files
    @api.all_resource_ids.map do |resource_id|
      PennArchivesSpaceFile.new(id: resource_id, api: @api)
    end
  end
end
