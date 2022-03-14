# frozen_string_literal: true

# Abstract class representing a single EAD from en Endpoint
class BaseEadFile
  attr_accessor :id, :xml

  class AbstractMethodCallError < StandardError; end

  def initialize(id:, endpoint:)
    @id = id
    @endpoint = endpoint
  end

  def xml
    raise AbstractMethodCallError, '#files method on BaseExtractor called. Implement this in your own Extractor class!'
  end
end
