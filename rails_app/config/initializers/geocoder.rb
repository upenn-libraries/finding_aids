# frozen_string_literal: true

# Use Nominatim (OpenStreetMap) for geocoding - free with rate limiting
# For initial bulk geocoding, use: GOOGLE_API_KEY=... bundle exec rake geocode:refresh
Geocoder.configure(
  lookup: :nominatim,
  ip_lookup: :ipinfo,
  cache: Rails.cache,
  timeout: 5,
  use_https: true,
  http_headers: { 'User-Agent' => 'FindingAidDiscovery/2.0 (University of Penn Libraries)' }
)
