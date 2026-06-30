# frozen_string_literal: true

Geocoder.configure(
  lookup: :google,
  api_key: Rails.application.credentials.google_api_key,
  cache: Rails.cache,
  timeout: 5
)
