# frozen_string_literal: true

Rails.application.config.to_prepare do
  Blacklight::UrlHelperBehavior.prepend(SearchHighlightUrlOverrides)
end
