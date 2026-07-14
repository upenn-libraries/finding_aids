# frozen_string_literal: true

# Prepend onto Blacklight's UrlHelperBehavior so our link_to_document
# override takes precedence over the engine's default.
module SearchHighlightUrlOverrides
  # Label resolution mirrors Blacklight::UrlHelperBehavior#link_to_document
  # — keep in sync on Blacklight upgrades.
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              document_presenter(doc).heading
            when Hash
              opts = field_or_opts
              document_presenter(doc).heading
            else
              field_or_opts
            end

    route_opts = {}
    route_opts[:q] = params[:q] if params[:q].present?
    link_to(label, solr_document_path(doc, route_opts), document_link_params(doc, opts))
  end
end
