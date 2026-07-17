# frozen_string_literal: true

module Aeon
  # Represent a request of one or more items to Aeon.
  # Expects to receive a hash with the following parameters:
  #  - repository (String)
  #  - title (String)
  #  - request type (String - "Copy" or "Loan", defaults to "Copy")
  #  - special_request (String)
  #  - notes (String)
  #  - retrieval_date (String with date in YYYY-MM-DD format)
  #  - save_for_later (Boolean)
  #  - return_url (String)
  #  - item (Array of Strings)
  #  - item_barcode (Array of Strings)
  class Request
    class InvalidRequestError < StandardError; end

    SCAN_REQUEST = 'Copy'
    VISIT_REQUEST = 'Loan'
    BASE_PARAMS = { SystemID: Settings.aeon.system_id,
                    WebRequestForm: 'DefaultRequest',
                    SubmitButton: 'Submit Request' }.freeze

    attr_reader :repository, :params

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
    end

    # Build indexed Item object from params, isolating individual collection requesting metadata
    # @return [Array[Aeon::Item]]
    def items
      @items ||= params['item'].map.with_index do |item, i|
        volume, issue = item.split(':').map(&:strip)
        volume += " [#{barcode(i)}]" if barcode(i).present?
        container_info = { volume: volume, issue: issue }
        Aeon::Item.new i + 1, container_info, self
      end
    end

    # @return [Hash{String (frozen)->String}]
    def note_fields
      { SpecialRequest: params[:special_request].to_s,
        Notes: params[:notes].to_s }
    end

    def settings_fields
      { UserReview: params[:save_for_later] == '1' ? 'Yes' : 'No',
        ReturnLinkUrl: params[:return_url].to_s,
        ReturnLinkSystemName: Settings.aeon.system_name }
    end

    # @return [Hash{String (frozen)->String}]
    def fulfillment_fields
      if params[:request_type] == VISIT_REQUEST
        { RequestType: VISIT_REQUEST,
          ScheduledDate: formatted_retrieval_date }
      else
        { RequestType: SCAN_REQUEST }
      end
    end

    # @return [Array<Array(String, String)>]
    def item_fields
      items.flat_map do |item|
        [['Request', item.number]] + item.to_h.to_a
      end
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

    # @return [Array<Array(String, String)>]
    def to_a
      BASE_PARAMS.to_a +
        note_fields.to_a +
        fulfillment_fields.to_a +
        settings_fields.to_a +
        item_fields
    end

    private

    # @return [String]
    def formatted_retrieval_date
      Date.parse(params['retrieval_date']).strftime('%m/%d/%Y')
    rescue StandardError => e
      Honeybadger.notify("Problem parsing retrieval date: #{e.message}")
      nil
    end

    # @return [Hash]
    # @param repository_name [String]
    def repository_info(repository_name)
      info = Settings.aeon.locations.find { |loc| loc[:label] == repository_name }
      raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting" unless info

      info
    end
  end
end
