# frozen_string_literal: true

module ApplicationHelper
  # Segments in a browser tab title are separated by a spaced middle dot (U+00B7),
  # per the Penn Libraries "page title" pattern.
  # @see https://designsystem.library.upenn.edu/patterns/page-title/
  PAGE_TITLE_SEPARATOR = ' · '

  # Override Blacklight's link_to_document to preserve the search query (q param)
  # in record page URLs, enabling arrival highlighting on show pages.
  # When params[:q] is present, merges it into the URL before link generation.
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label, link_to_opts = resolve_link_to_document_args(doc, field_or_opts, opts)
    url = search_state.url_for_document(doc)
    url = url.merge(q: params[:q]) if params[:q].present?
    link_to(label, url, document_link_params(doc, link_to_opts))
  end

  # @return [Boolean]
  def render_clarity_script?
    Settings.ms_clarity&.id.present?
  end

  # Assembles the browser tab (<title>) text following the Penn Libraries
  # "page title" pattern: "Page name · Application name · Penn Libraries".
  # Pages without a page-specific title (e.g. the homepage) collapse to the
  # "Application name · Penn Libraries" variant.
  #
  # The page-name segment comes from the same content_for(:page_title)/@page_title
  # inputs Blacklight populates, so per-page titles keep working; we compose the
  # full title here rather than overriding Blacklight's render_page_title to avoid
  # helper precedence surprises. The layout passes @page_title in (it's read there,
  # in the view, rather than as an instance variable inside this helper).
  # @see https://designsystem.library.upenn.edu/patterns/page-title/
  # @param page_title [String, nil] fallback page name when no content_for(:page_title) is set
  # @return [String]
  def full_page_title(page_title = nil)
    page_name = content_for(:page_title) || page_title
    [page_name, application_name, t('blacklight.organization_name')]
      .filter_map { |segment| segment.to_s.strip.presence }
      .join(PAGE_TITLE_SEPARATOR)
  end

  # Custom helper method use by Blacklight to truncate abstract.
  # @param options [Hash]
  # @return [ActiveSupport::SafeBuffer]
  def truncated_abstract(options)
    truncate(options[:value].first, length: 1_000, separator: ' ') do
      link_to '(see more)', solr_document_path(options[:document])
    end
  end

  # @param options [Hash]
  def extent_display(options)
    options[:value].one? ? options[:value].first : unordered_list(options)
  end

  # @param options [Hash]
  # @return [ActiveSupport::SafeBuffer]
  def unordered_list(options)
    content_tag :ul do
      options[:value].map do |item|
        concat content_tag(:li, item)
      end
    end
  end

  private

  # Unpacks Blacklight's overloaded link_to_document signature:
  #   link_to_document(doc, label, counter: N)
  #   link_to_document(doc, opts, {counter: N})  (label from doc heading)
  #   link_to_document(doc, counter: N)          (label from doc heading)
  # Returns [label, link_to_options_hash].
  def resolve_link_to_document_args(doc, field_or_opts, opts)
    case field_or_opts
    when NilClass
      [document_presenter(doc).heading, opts]
    when Hash
      [document_presenter(doc).heading, field_or_opts]
    else
      [field_or_opts, opts]
    end
  end
end
