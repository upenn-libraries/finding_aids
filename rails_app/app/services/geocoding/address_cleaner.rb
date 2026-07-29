# frozen_string_literal: true

module Geocoding
  # Shared regex constants and helpers for cleaning repository addresses.
  # Used by both the EAD parser (raw XML to clean address) and the
  # geocoding service (pre-geocode sanitization).
  module AddressCleaner
    # Matches phone numbers (various formats), email addresses, and URLs.
    #   "(215) 555-1234", "info@example.org", "http://..."
    CONTACT_PATTERN = /\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}|@|URL|http/
    # Matches lines that don't start with a digit — used to identify building
    # names like "Falvey Library" that should be dropped.
    BUILDING_NAME_PATTERN = /\A(?!\d).*\z/
    # Matches parenthetical notes: "(2nd floor)", "(hours: 9-5)"
    PARENTHETICAL_PATTERN = /\(.*?\)/
    # Matches double commas left by naively stripped content.
    DOUBLE_COMMA_PATTERN = /,\s*,/

    # Strip parenthetical notes and double commas from an address string.
    def self.clean(address)
      address.gsub(PARENTHETICAL_PATTERN, '').gsub(DOUBLE_COMMA_PATTERN, ',').gsub(/\s+,/, ',').strip
    end
  end
end
