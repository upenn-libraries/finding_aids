# frozen_string_literal: true

module Aeon
  # Represent a request of one or more items to Aeon
  class Request
    class InvalidRequestError < StandardError; end

    BASE_PARAMS = { AeonForm: 'EADRequest',
                    WebRequestForm: 'DefaultRequest',
                    SubmitButton: 'Submit Request' }.freeze

    attr_reader :items, :repository

    # Is requesting enabled for this repository?
    # @param repository_name [String]
    # @return [Boolean]
    def self.allowed?(repository_name:)
      Settings.aeon.locations.any? { |loc| loc[:label] == repository_name }
    end

    # @param [ActiveSupport::HashWithIndifferentAccess] params
    def initialize(params)
      @repository = repository_info params[:repository].to_s
      @params = params
      @items = build_items
    end

    # @return [Array[Aeon::Item]]
    def build_items
      @params['item'].map.with_index do |item, i|
        volume, issue = item.split(':').map(&:strip)
        volume += " [#{barcode(i)}]" if barcode(i).present?
        container_info = { volume: volume, issue: issue }
        Aeon::Item.new i, container_info, self
      end
    end

    # @return [Hash]
    # @param [String] repository_name
    def repository_info(repository_name)
      info = Settings.aeon.locations.find { |loc| loc[:label] == repository_name }
      raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting" unless info

      info
    end

    # @return [Hash{String (frozen)->String}]
    def note_fields
      { 'SpecialRequest' => @params[:special_request].to_s,
        'Notes' => @params[:notes].to_s }
    end

    # @return [Hash{String (frozen)->String}]
    def fulfillment_fields
      { 'UserReview' => @params[:save_for_later] == '1' ? 'Yes' : 'No',
        'ScheduledDate' => formatted_retrieval_date }
    end

    # @return [String]
    def formatted_retrieval_date
      Date.parse(@params['retrieval_date']).strftime('%m/%d/%Y')
    end

    # @return [String]
    def call_number
      @params[:call_num]
    end

    # @return [String]
    def title
      @params[:title]
    end

    # @return [String]
    # @param [Integer] index
    def barcode(index)
      @params[:item_barcode][index]
    end

    # @return [Hash]
    def to_h
      item_fields = {}
      @items.each do |i|
        i.to_h.each do |k, v|
          item_fields[k] = v
        end
      end
      BASE_PARAMS.merge(note_fields)
                 .merge(fulfillment_fields)
                 .merge(item_fields)
    end

    # @return [Hash{Symbol->String (frozen)]
    def prepared
      { url: Settings.aeon.ere_endpoint,
        body: to_h }
    end
  end
end
