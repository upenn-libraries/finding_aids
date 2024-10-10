# frozen_string_literal: true

# Extract XML content from ArchivesSpace Instance
class ASpaceExtractor < BaseExtractor
  attr_reader :endpoint

  # @param [Endpoint] endpoint
  def initialize(endpoint:)
    @api = ASpaceService.new(aspace_instance: endpoint.aspace_instance, repository_id: endpoint.aspace_repo_id)
    super endpoint: endpoint
  end

  # return iterable of ArchivesSpaceFiles
  # @return [Array]
  def files
    @files ||= build_aspace_files
  end

  # Pretend the API is like a file
  class ASpaceFile < BaseEadSource
    attr_reader :id

    # @param [String] id
    # @param [ASpaceService] api aspace api service
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

  def build_aspace_files
    @api.all_resource_ids.map do |resource_id|
      ASpaceFile.new(id: resource_id, api: @api)
    end
  end
end
