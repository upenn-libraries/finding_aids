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

  # Represent an individual EAD file - with an id and xml
  class BaseEadSource
    attr_accessor :id

    def initialize(id:)
      @id = id
    end

    def xml
      raise(
        BaseExtractor::AbstractMethodCallError,
        '#files method on BaseExtractor::BaseEadSource called. Implement this in your own class!'
      )
    end
  end
end
