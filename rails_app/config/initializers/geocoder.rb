# frozen_string_literal: true

# Use Nominatim (OpenStreetMap) for geocoding - free with rate limiting
# For initial bulk geocoding, temporarily switch to Google in this file:
#   lookup: :google, api_key: Rails.application.credentials.google_api_key
Geocoder.configure(
  lookup: :nominatim,
  ip_lookup: :ipinfo,
  cache: Rails.cache,
  timeout: 5,
  use_https: true,
  http_headers: { 'User-Agent' => 'UPENN Finding Aids' }
)
