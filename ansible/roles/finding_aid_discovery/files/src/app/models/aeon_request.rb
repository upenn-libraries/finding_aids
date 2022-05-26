# frozen_string_literal: true

# Represent a request of one or more items to Aeon
class AeonRequest
  class InvalidRequestError < StandardError; end

  KISLAK_REPOSITORY_NAME =
    'University of Pennsylvania: Kislak Center for Special Collections, Rare Books and Manuscripts'
  KISLAK_REPOSITORY_ATTRIBUTES = { site: 'KISLAK', location: 'scmss', sublocation: 'Manuscripts' }.freeze

  KATZ_REPOSITORY_NAME =
    'University of Pennsylvania: Archives at the Library of the Katz Center for Advanced Judaic Studies'
  KATZ_REPOSITORY_ATTRIBUTES = { site: 'KATZ', location: 'cjsarcms', sublocation: 'Arc Room Ms.' }.freeze

  BASE_PARAMS = { AeonForm: 'EADRequest', WebRequestForm: 'DefaultRequest', SubmitButton: 'Submit Request' }.freeze

  PENN_AUTH_INFO = { url: 'https://aeon.library.upenn.edu/aeon/aeon.dll', param: '1' }.freeze
  EXT_AUTH_INFO = { url: 'https://aeon.library.upenn.edu/nonshib/aeon.dll', param: '2' }.freeze

  attr_reader :items, :repository

  # @param [ActiveSupport::HashWithIndifferentAccess] params
  def initialize(params)
    @repository = repository_info params[:repository].to_s
    @params = params
    @items = build_items
  end

  # @return [Array[AeonRequest::Item]]
  def build_items
    @params['item'].map.with_index do |item, i|
      volume, issue = item.split(':').map(&:strip)
      container_info = { volume: volume, issue: issue }
      Item.new i, container_info, self
    end
  end

  # @return [Hash]
  # @param [String] repository_name
  def repository_info(repository_name)
    case repository_name
    when KISLAK_REPOSITORY_NAME
      KISLAK_REPOSITORY_ATTRIBUTES
    when KATZ_REPOSITORY_NAME
      KATZ_REPOSITORY_ATTRIBUTES
    else
      raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting"
    end
  end

  # @return [Hash{Symbol->String (frozen)}]
  def auth_info
    case @params[:auth_type]
    when 'penn' then PENN_AUTH_INFO
    when 'external' then EXT_AUTH_INFO
    else
      raise InvalidRequestError, "Invalid auth type specified: #{@params[:auth_type]}"
    end
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
    day = @params['retrieval_date(3i)'].to_i
    month = @params['retrieval_date(2i)'].to_i
    year = @params['retrieval_date(1i)'].to_i
    DateTime.new(year, month, day).strftime('%m/%d/%Y')
  end

  # @return [Hash{String (frozen)->String (frozen)}]
  def auth_param
    { 'auth' => auth_info[:param] }
  end

  # @return [String]
  def call_number
    @params[:call_num]
  end

  # @return [String]
  def title
    @params[:title]
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
               .merge(auth_param)
               .merge(fulfillment_fields)
               .merge(item_fields)
  end

  # @return [Hash{Symbol->String (frozen)]
  def prepared
    { url: auth_info[:url],
      body: to_h }
  end

  # Represent a single Item (checked box in the site) in the context of the request
  class Item
    # @param [Hash] container
    # @param [AeonRequest] request
    # @param [String] number
    def initialize(number, container, request)
      @number = number
      @container = container
      @request = request
    end

    def to_h
      hash = { 'CallNumber' => @request.call_number, 'ItemTitle' => @request.title, 'ItemAuthor' => '',
               'Site' => @request.repository[:site], 'SubLocation' => @request.repository[:sublocation],
               'Location' => @request.repository[:location], 'ItemVolume' => @container[:volume],
               'ItemIssue' => @container[:issue] }
             .transform_keys { |key| key + "_#{@number}" }
      hash.store('Request', @number)
      hash
    end
  end
end
