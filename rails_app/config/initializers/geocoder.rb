# frozen_string_literal: true

Geocoder.configure(
  lookup: :nominatim,
  cache: Rails.cache,
  timeout: 5,
  http_headers: { 'User-Agent' => "FindingAidsDiscovery/#{Settings.version || '1.0'} (PACSCL)" },
  always_raise: [Geocoder::OverQueryLimitError]
)
