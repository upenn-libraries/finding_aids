# frozen_string_literal: true

# Prepend onto Blacklight's UrlHelperBehavior so our link_to_document
# override takes precedence over the engine's default.
module SearchHighlightUrlOverrides
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

    url = solr_document_path(doc)
    url = "#{url}?q=#{CGI.escape(params[:q])}" if params[:q].present?
    link_to(label, url, document_link_params(doc, opts))
  end
end
