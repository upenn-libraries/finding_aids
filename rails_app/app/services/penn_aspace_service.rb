# frozen_string_literal: true

# simple wrapper for the gem-provided ASpace API
class PennAspaceService
  # @param [String] repository_id
  def initialize(repository_id)
    client.repository(repository_id)
  end

  # Get IDs for all published resources in the repository
  # It would be nice if we could use the `all_ids: true` functionality of the API
  # while also querying only for publish: true items
  # @return [Array]
  def all_resource_ids
    resources = client.resources # Enumerator.lazy here
    published_resources = resources.select { |r| r['publish'] == true }
    # there's no ID in the response, but we can extract it from the URI
    published_resources.map { |r| r['uri'].split('/').last }.to_a
  end

  # @param [String] resource_id
  # @return [String]
  def resource_ead_xml(resource_id)
    params = { include_unpublished: false, include_daos: true }
    client.get("resource_descriptions/#{resource_id}.xml?#{params.to_param}").body
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
        username: DockerSecrets.lookup(:penn_aspace_api_username),
        password: DockerSecrets.lookup(:penn_aspace_api_password),
        page_size: 50, throttle: 0.1,
        debug: false, verify_ssl: false
      }
    )
  end
end
