# frozen_string_literal: true

# Abstract class facilitating the extraction of EadFiles from an Endpoint
class BaseExtractor
  attr_reader :endpoint

  class AbstractMethodCallError < StandardError; end

  def initialize(endpoint:)
    raise(StandardError, "Endpoint not provided to Extractor class #{self.class.name}") unless endpoint.is_a? Endpoint

    @endpoint = endpoint
  end

  # no-op
  def files
    raise AbstractMethodCallError, '#files method on BaseExtractor called. Implement this in your own Extractor class!'
  end

  # Represent an individual EAD file
  class BaseEadSource
    # Returns raw xml.
    def xml
      raise(
        BaseExtractor::AbstractMethodCallError,
        '#xml method on BaseExtractor::BaseEadSource called. Implement this in your own class!'
      )
    end

    # Return identifier for the source context. This is used when displaying error messages.
    def source_id
      raise(
        BaseExtractor::AbstractMethodCallError,
        '#source_id method on BaseExtractor::BaseEadSource called. Implement this in your own class!'
      )
    end
  end
end
