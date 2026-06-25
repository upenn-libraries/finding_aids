# frozen_string_literal: true

# Blacklight controller configuring search and record pages.
class CatalogController < ApplicationController
  include Blacklight::Catalog

  before_action :load_homepage_data, only: :index
  before_action :load_regional_repos, unless: -> { request.format.json? || request.format.turbo_frame? }

  def index
    super
  end

  configure_blacklight do |config|
    config.bootstrap_version = 5
    config.header_component = HeaderComponent
    config.index.search_bar_component = Catalog::SearchBarComponent
    config.index.constraints_component = Catalog::ConstraintsComponent
    config.index.search_header_component = Catalog::SearchHeaderComponent
    config.show.document_component = Catalog::ShowDocumentComponent
    config.show.document_presenter_class = Catalog::ShowDocumentPresenter
    config.advanced_search.enabled = false

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
    # Include only the fields needed to render the search results - mostly, don't return stored XML field
    config.default_solr_params = {
      rows: 10,
      fl: 'id title_tsi extent_ssim display_date_ssim abstract_scope_contents_tsi genre_form_ssim
           repository_ssi creators_ssim repository_name_component_1_ssi contact_emails_ssm'
    }

    config.default_document_solr_params = {} # Use default in solrconfig

    # disable tracking links since we don't allow paginating through a results set
    config.track_search_session = Blacklight::OpenStructWithHashAccess.new({ storage: false })

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'
    # config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    # First value is the default page size (no default_per_page set), matching our other Blacklight apps.
    config.per_page = [25, 50, 100]

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

    config.add_facet_field 'repository_ssi', label: I18n.t('fields.repository'), limit: true
    config.add_facet_field 'record_source', label: I18n.t('fields.record_source'), query: {
      upenn: { label: 'University of Pennsylvania', fq: 'upenn_record_bsi:true' },
      non_upenn: { label: 'Other PACSCL Partners', fq: 'upenn_record_bsi:false' }
    }
    config.add_facet_field 'online_content', label: I18n.t('fields.online_content'), query: {
      yes: { label: 'Has Online Content', fq: 'online_content_bsi:true' },
      no: { label: 'Not Available', fq: 'online_content_bsi:false' }
    }
    config.add_facet_field 'subjects_ssim', label: I18n.t('fields.topics.subjects'), limit: true
    config.add_facet_field 'corpnames_ssim', label: I18n.t('fields.topics.corpnames'), limit: true
    config.add_facet_field 'people_ssim', label: I18n.t('fields.topics.people'), limit: true
    config.add_facet_field 'places_ssim', label: I18n.t('fields.topics.places'), limit: true
    config.add_facet_field 'occupations_ssim', label: I18n.t('fields.topics.occupations'), limit: true
    config.add_facet_field 'genre_form_ssim', label: I18n.t('fields.genre_form'), limit: true
    config.add_facet_field 'creators_ssim', label: I18n.t('fields.creators'), limit: true
    config.add_facet_field 'donors_ssim', label: I18n.t('fields.donors'), limit: true
    config.add_facet_field 'languages_ssim', label: I18n.t('fields.language'), limit: true
    config.add_facet_field 'era_facet', label: I18n.t('facets.era.label'), solr_params:
      { 'facet.mincount': 1 }, query: {
        first_millennium: { label: I18n.t('facets.era.millennium.first'), fq: 'years_iim:[0001 TO 1000]' },
        eleventh_century: { label: I18n.t('facets.era.century.eleventh'), fq: 'years_iim:[1001 TO 1100]' },
        twelfth_century: { label: I18n.t('facets.era.century.twelfth'), fq: 'years_iim:[1101 TO 1200]' },
        thirteenth_century: { label: I18n.t('facets.era.century.thirteenth'), fq: 'years_iim:[1201 TO 1300]' },
        fourteenth_century: { label: I18n.t('facets.era.century.fourteenth'), fq: 'years_iim:[1301 TO 1400]' },
        fifteenth_century: { label: I18n.t('facets.era.century.fifteenth'), fq: 'years_iim:[1401 TO 1500]' },
        sixteenth_century: { label: I18n.t('facets.era.century.sixteenth'), fq: 'years_iim:[1501 TO 1600]' },
        seventeenth_century: { label: I18n.t('facets.era.century.seventeenth'), fq: 'years_iim:[1601 TO 1700]' },
        eighteenth_century: { label: I18n.t('facets.era.century.eighteenth'), fq: 'years_iim:[1701 TO 1800]' },
        nineteenth_century: { label: I18n.t('facets.era.century.nineteenth'), fq: 'years_iim:[1801 TO 1900]' },
        twentieth_century: { label: I18n.t('facets.era.century.twentieth'), fq: 'years_iim:[1901 TO 2000]' },
        twenty_first_century: { label: I18n.t('facets.era.century.twenty-first'), fq: 'years_iim:[2001 TO 2100]' }
      }
    config.add_facet_field 'endpoint_ssi', label: I18n.t('fields.endpoint'), limit: true, unless: Rails.env.production?

    config.add_facet_fields_to_solr_request!

    config.add_index_field 'title_tsi', label: I18n.t('fields.title'), if: :json_request?
    config.add_index_field 'extent_ssim', label: I18n.t('fields.extent')
    config.add_index_field 'display_date_ssim', label: I18n.t('fields.date')
    config.add_index_field 'subjects_ssim', label: I18n.t('fields.topics.subjects'), if: :json_request?
    config.add_index_field 'genre_form_ssim', label: I18n.t('fields.genre_form'), if: :json_request?
    config.add_index_field 'creators_ssim', label: I18n.t('fields.creators'), if: :json_request?
    config.add_index_field 'repository_ssi', label: I18n.t('fields.repository'), link_to_facet: true
    config.add_index_field 'abstract_scope_contents_tsi', label: I18n.t('fields.abstract_scope_contents'),
                                                          helper_method: :truncated_abstract

    config.add_show_field 'abstract_scope_contents_tsi', label: I18n.t('fields.abstract_scope_contents')
    config.add_show_field 'repository_ssi', label: I18n.t('fields.repository'), link_to_facet: true

    # collection overview
    config.add_show_field 'creators_ssim', label: I18n.t('fields.creators'), link_to_facet: true,
                                           group: :collection_overview
    config.add_show_field 'display_date_ssim', label: I18n.t('fields.date'), group: :collection_overview
    config.add_show_field 'extent_ssim', label: I18n.t('fields.extent'), helper_method: :extent_display,
                                         group: :collection_overview
    config.add_show_field 'pretty_unit_id_ss', label: I18n.t('fields.pretty_unit_id'), group: :collection_overview

    # subject and headings
    config.add_show_field 'subjects_ssim', label: I18n.t('fields.topics.subjects'), link_to_facet: true,
                                           group: :subjects_and_headings
    config.add_show_field 'people_ssim', label: I18n.t('fields.topics.people'), link_to_facet: true,
                                         group: :subjects_and_headings
    config.add_show_field 'corpnames_ssim', label: I18n.t('fields.topics.corpnames'), link_to_facet: true,
                                            group: :subjects_and_headings
    config.add_show_field 'places_ssim', label: I18n.t('fields.topics.places'), link_to_facet: true,
                                         group: :subjects_and_headings
    config.add_show_field 'occupations_ssim', label: I18n.t('fields.topics.occupations'), link_to_facet: true,
                                              group: :subjects_and_headings
    config.add_show_field 'languages_ssim', label: I18n.t('fields.language'), link_to_facet: true,
                                            group: :subjects_and_headings
    config.add_show_field 'genre_form_ssim', label: I18n.t('fields.genre_form'), link_to_facet: true,
                                             group: :subjects_and_headings

    # rights and citations
    config.add_show_field 'use_restrictions', label: I18n.t('fields.use'), group: :rights_and_citation,
                                              accessor: :use_restrictions
    config.add_show_field 'preferred_citation_ss', label: I18n.t('fields.citation'), group: :rights_and_citation

    # contact
    config.add_show_field 'repository_address_ssi', label: I18n.t('fields.repository_address'), group: :contact
    config.add_show_field 'contact_emails_ssm', label: I18n.t('fields.contact_email'), group: :contact,
                                                presenter: Catalog::EmailFieldPresenter
    config.add_show_field 'link_url_ss', label: I18n.t('fields.url'), group: :contact, presenter: Catalog::UrlFieldPresenter

    # TODO: where to render these?
    config.add_show_field 'language_note', label: I18n.t('fields.language_note'), accessor: :language_note,
                                           if: :render_language_note?
    config.add_show_field 'donors_ssim', label: I18n.t('fields.donors'), link_to_facet: true

    config.add_show_field 'xml_ss', label: I18n.t('fields.xml')
    config.add_search_field 'all_fields', label: 'All Fields'

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the Solr field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case). Add the sort: option to configure a
    # custom Blacklight url parameter value separate from the Solr sort fields.
    config.add_sort_field 'relevance', sort: 'score desc', label: I18n.t('sorts.relevance')
    config.add_sort_field 'year-desc', sort: 'years_iim desc, title_ssort asc, score desc',
                                       label: I18n.t('sorts.year_desc')
    config.add_sort_field 'year-asc', sort: 'years_iim asc, title_ssort asc, score desc',
                                      label: I18n.t('sorts.year_asc')
    config.add_sort_field 'title-desc', sort: 'title_ssort desc, score desc', label: I18n.t('sorts.title_desc')
    config.add_sort_field 'title-asc', sort: 'title_ssort asc, score desc', label: I18n.t('sorts.title_asc')

    # Configuration for autocomplete suggester
    config.autocomplete_enabled = false
  end

  def upenn
    redirect_to search_catalog_path({ 'f[record_source][]': 'upenn' })
  end

  private

  def json_request?
    request.format.json?
  end

  # render dynamically parsed language note if it's different from indexed language field
  # @param document [SolrDocument]
  # @return [Boolean]
  def render_language_note?(_field_config, document)
    note = document.language_note
    languages = document.fetch(:languages_ssim, []).join

    note.present? && languages.gsub(/[^0-9a-zA-Z]/, '') != note.gsub(/[^0-9a-zA-Z]/, '')
  end

  def load_homepage_data
    return if has_search_parameters?

    @homepage_guides = HomepageData.collection_guides.sample(8)
  end
end
