# frozen_string_literal: true

module Aeon
  # Represent a request of one or more items to Aeon
  class Request
    class InvalidRequestError < StandardError; end

    BASE_PARAMS = { AeonForm: 'ExternalRequest',
                    SystemID: Settings.aeon.system_id,
                    WebRequestForm: 'DefaultRequest',
                    SubmitButton: 'Submit Request' }.freeze

    attr_reader :items, :repository, :params

    # Is requesting enabled for this repository?
    # @param repository_name [String]
    # @return [Boolean]
    def self.allowed?(repository_name:)
      Settings.aeon.locations.any? { |loc| loc[:label] == repository_name }
    end

    # @param params [ActiveSupport::HashWithIndifferentAccess]
    def initialize(params)
      @repository = repository_info params[:repository].to_s
      @params = params
      @items = build_items
    end

    # @return [Array[Aeon::Item]]
    def build_items
      params['item'].map.with_index do |item, i|
        volume, issue = item.split(':').map(&:strip)
        volume += " [#{barcode(i)}]" if barcode(i).present?
        container_info = { volume: volume, issue: issue }
        Aeon::Item.new i, container_info, self
      end
    end

    # @return [Hash]
    # @param repository_name [String]
    def repository_info(repository_name)
      info = Settings.aeon.locations.find { |loc| loc[:label] == repository_name }
      raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting" unless info

      info
    end

    # @return [Hash{String (frozen)->String}]
    def note_fields
      { 'SpecialRequest' => params[:special_request].to_s,
        'Notes' => params[:notes].to_s }
    end

    def settings_fields
      { 'UserReview' => params[:save_for_later] == '1' ? 'Yes' : 'No',
        'ReturnLinkUrl' => params[:return_url],
        'ReturnLinkSystemName' => Settings.aeon.system_name }
    end

    # @return [Hash{String (frozen)->String}]
    def fulfillment_fields
      if params[:request_type] == 'Loan'
        { 'RequestType' => 'Loan',
          'ScheduledDate' => formatted_retrieval_date }
      else
        { 'RequestType' => 'Copy' }
      end
    end

    # @return [String]
    def formatted_retrieval_date
      Date.parse(params['retrieval_date']).strftime('%m/%d/%Y')
    rescue StandardError => _e
      Honeybadger.notify("Problem parsing retrieval date: #{e.message}")
      nil
    end

    # @return [String]
    def call_number
      params[:call_num]
    end

    # @return [String]
    def title
      params[:title]
    end

    # @param index [Integer]
    # @return [String]
    def barcode(index)
      params[:item_barcode][index]
    end

    # @return [Hash]
    def to_h
      item_fields = {}
      items.each do |i|
        i.to_h.each do |k, v|
          item_fields[k] = v
        end
      end
      BASE_PARAMS.merge(note_fields)
                 .merge(fulfillment_fields)
                 .merge(settings_fields)
                 .merge(item_fields)
    end

    # @return [Hash{Symbol->String (frozen)]
    def prepared
      { url: Settings.aeon.ere_endpoint,
        body: to_h }
    end
  end
end
