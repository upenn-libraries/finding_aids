# frozen_string_literal: true

module Aeon
  # Represent a single Item (checked box in the site) in the context of the request
  class Item
    attr_accessor :number, :issue, :barcode, :request

    delegate :repository, to: :request

    # @param number [Integer]
    # @param description [String]
    # @param request [Aeon::Request]
    # @param barcode [String]
    def initialize(number:, description:, request:, barcode: nil)
      @number = number
      @volume, @issue = description.split(':').map(&:strip)
      @request = request
      @barcode = barcode
    end

    # @return [String]
    def volume
      barcode.present? ? "#{@volume} [#{@barcode}]" : volume
    end

    # @return [Hash{Symbol->Unknown}]
    def to_h
      { Request: number,
        CallNumber: request.call_number,
        ItemTitle: request.title,
        Site: repository.site,
        SubLocation: repository.sublocation,
        Location: repository.location,
        ItemVolume: volume,
        ItemIssue: issue }
    end

    # Represent params in an array with indexed "keys". "Request" param will be duplicated.
    # @return [Array<Array>]
    def params_as_array
      to_h
        .transform_keys { |key| key == :Request ? key.to_s : "#{key}_#{number}" }
        .to_a
    end

    private

    # @param [String] name
    # @param [Integer] index
    # @return [String]
    def indexed_param(name, index)
      "#{name}_#{index}"
    end
  end
end
