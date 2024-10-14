# frozen_string_literal: true

# controller actions for directory-level API responses
class ApiController < ApplicationController
  include Blacklight::Searchable

  respond_to :json

  ENDPOINTS_FACET = 'endpoint_ssi'
  REPO_FACET = 'repository_ssi'

  def endpoints
    @entries = facet_response facet_field: ENDPOINTS_FACET
    render json: @entries
  end

  def repositories
    @entries = facet_response facet_field: REPO_FACET
    render json: @entries
  end

  private

  # @param facet_field [String]
  # @return [Array<Hash>]
  def facet_response(facet_field:)
    facet_config = blacklight_config.facet_fields[facet_field]
    response = search_service.facet_field_response(facet_config.key, { "f.#{facet_field}.facet.limit" => -1 })
    field_data = response.aggregations[facet_field]
    field_data.items.map { |entry| hashify_with_link(field: facet_field, item: entry) }.sort_by { |h| h[:name] }
  end

  # @param field [String]
  # @param item [Blacklight::Solr::Response::Facets::FacetItem]
  # @return [Hash{Symbol->String}]
  def hashify_with_link(field:, item:)
    { name: item.value, count: item.hits,
      records_url: facet_entry_url(entry: item.value, field: field) }
  end

  # @param entry [String]
  # @param field [String]
  # @return [String]
  def facet_entry_url(entry:, field:)
    search_catalog_url("f[#{field}][]" => entry, format: :json)
  end
end
