# frozen_string_literal: true

module Aeon
  # Represent a single Item (checked box in the site) in the context of the request
  class Item
    attr_accessor :number

    # @param number [String]
    # @param container [Hash]
    # @param request [Aeon::Request]
    def initialize(number, container, request)
      @number = number
      @container = container
      @request = request
    end

    # @return [Hash{String->String}]
    def to_h
      { 'CallNumber' => @request.call_number,
        'ItemTitle' => @request.title,
        'ItemAuthor' => '',
        'Site' => @request.repository[:site],
        'SubLocation' => @request.repository[:sublocation],
        'Location' => @request.repository[:location],
        'ItemVolume' => @container[:volume],
        'ItemIssue' => @container[:issue] }.transform_keys { |key| key + "_#{@number}" }
    end
  end
end
