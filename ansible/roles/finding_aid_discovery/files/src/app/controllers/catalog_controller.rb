# frozen_string_literal: true

# Blacklight controller configuring search and record pages.
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightRangeLimit::ControllerOverride

  layout 'pacscl_blacklight'

  configure_blacklight do |config|
    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response
    #
    ## Should the raw solr document endpoint (e.g. /catalog/:id/raw) be enabled
    # config.raw_endpoint.enabled = false

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'
    # config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10, 20, 50, 100]

    # solr field configuration for search results/index views
    config.index.title_field = :title_tsi
    # config.index.display_type_field = 'format'
    # config.index.thumbnail_field = 'thumbnail_path_ss'

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    # solr field configuration for document/show views
    # config.show.title_field = :title_tsi
    # config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically
    #   across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation
    #              (note: It is case sensitive when searching values)

    config.add_facet_field 'endpoint_ssi', label: I18n.t('fields.endpoint'), limit: true
    config.add_facet_field 'repository_ssi', label: I18n.t('fields.repository'), limit: true
    config.add_facet_field 'record_source', label: I18n.t('fields.record_source'), query: {
      upenn: { label: 'University of Pennsylvania', fq: 'upenn_record_bsi:true' },
      non_upenn: { label: 'Other PACSCL Partners', fq: 'upenn_record_bsi:false' }
    }
    config.add_facet_field 'subjects_ssim', label: I18n.t('fields.topics.subjects'), limit: true
    config.add_facet_field 'corpnames_ssim', label: I18n.t('fields.topics.corpnames'), limit: true
    config.add_facet_field 'people_ssim', label: I18n.t('fields.topics.people'), limit: true
    config.add_facet_field 'places_ssim', label: I18n.t('fields.topics.places'), limit: true
    config.add_facet_field 'genre_form_ssim', label: I18n.t('fields.genre_form'), limit: true
    config.add_facet_field 'creators_ssim', label: I18n.t('fields.creators'), limit: true
    config.add_facet_field 'donors_ssim', label: I18n.t('fields.donors'), limit: true
    config.add_facet_field 'languages_ssim', label: I18n.t('fields.language'), limit: true
    config.add_facet_field 'years_iim', label: I18n.t('fields.year'), range: true

    config.add_facet_fields_to_solr_request!

    config.add_index_field 'extent_ssi', label: I18n.t('fields.extent')
    # config.add_index_field 'display_date_ssim', label: I18n.t('fields.date')
    config.add_index_field 'abstract_scope_contents_tsi', label: I18n.t('fields.abstract_scope_contents'),
                                                          helper_method: :truncated_abstract

    config.add_show_field 'pretty_unit_id_ss', label: I18n.t('fields.pretty_unit_id')
    config.add_show_field 'repository_ssi', label: I18n.t('fields.repository'), link_to_facet: true
    config.add_show_field 'url_ss', label: 'Original URL'
    config.add_show_field 'extent_ssi', label: I18n.t('fields.extent')
    config.add_show_field 'languages_ssim', label: I18n.t('fields.language'), link_to_facet: true
    config.add_show_field 'preferred_citation_ss', label: I18n.t('fields.citation')
    config.add_show_field 'display_date_ssim', label: I18n.t('fields.date')
    config.add_show_field 'creators_ssim', label: I18n.t('fields.creators'), link_to_facet: true
    config.add_show_field 'donors_ssim', label: I18n.t('fields.donors'), link_to_facet: true
    config.add_show_field 'genre_form_ssim', label: I18n.t('fields.genre_form'), link_to_facet: true
    config.add_show_field 'abstract_scope_contents_tsi', label: I18n.t('fields.abstract_scope_contents')

    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the Solr field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case). Add the sort: option to configure a
    # custom Blacklight url parameter value separate from the Solr sort fields.
    config.add_sort_field 'relevance', sort: 'score desc', label: I18n.t('sorts.relevance')
    config.add_sort_field 'year-desc', sort: 'years_iim desc, score desc', label: I18n.t('sorts.year_desc')
    config.add_sort_field 'year-asc', sort: 'years_iim asc, score desc', label: I18n.t('sorts.year_asc')

    # Configuration for autocomplete suggester
    config.autocomplete_enabled = false

    # Use local Document component to customize results and show page views
    config.index.document_component = DocumentComponent
    config.show.document_component = DocumentComponent
  end

  def repositories
    @facet = blacklight_config.facet_fields['repository_ssi']
    raise ActionController::RoutingError, 'Not Found' unless @facet

    @response = search_service.facet_field_response(@facet.key, { 'f.repository_ssi.facet.limit' => -1 })
    @display_facet = @response.aggregations[@facet.field]

    @presenter = @facet.presenter.new(@facet, @display_facet, view_context)
    @pagination = @presenter.paginator
  end
end
