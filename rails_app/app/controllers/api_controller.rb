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

  # @param [String] facet_field
  # @return [Array<Hash>] ????
  def facet_response(facet_field:)
    facet_config = blacklight_config.facet_fields[facet_field]
    response = search_service.facet_field_response(facet_config.key, { "f.#{facet_field}.facet.limit" => -1 })
    field_data = response.aggregations[facet_field]
    field_data.items.map { |entry| hashify_with_link(facet_field, entry) }
  end

  # @param [String] facet_field
  # @param [Blacklight::Solr::Response::Facets::FacetItem] facet_item
  # @return [Hash{Symbol->String}]
  def hashify_with_link(facet_field, facet_item)
    { name: facet_item.value, count: facet_item.hits,
      records_url: facet_entry_url(entry: facet_item.value, field: facet_field) }
  end

  def facet_entry_url(entry:, field:)
    search_catalog_url("f[#{field}][]" => entry)
  end
end
