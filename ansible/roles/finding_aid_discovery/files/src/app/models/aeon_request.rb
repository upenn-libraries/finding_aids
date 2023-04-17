# frozen_string_literal: true

# Represent a request of one or more items to Aeon
class AeonRequest
  class InvalidRequestError < StandardError; end

  AEON_URL = 'https://aeon.library.upenn.edu'

  KISLAK_REPOSITORY_NAME =
    'University of Pennsylvania: Kislak Center for Special Collections, Rare Books and Manuscripts'
  KATZ_REPOSITORY_NAME =
    'University of Pennsylvania: Archives at the Library of the Katz Center for Advanced Judaic Studies'
  ARCHIVES_REPOSITORY_NAME =
    'University of Pennsylvania: University Archives and Records Center'

  REPOSITORY_ATTRIBUTE_MAP = {
    ARCHIVES_REPOSITORY_NAME => { site: 'UARCHIVES', location: 'uarcmss', sublocation: 'Reading Rm' },
    KATZ_REPOSITORY_NAME => { site: 'KATZ', location: 'cjsarcms', sublocation: 'Arc Room Ms.' },
    KISLAK_REPOSITORY_NAME => { site: 'KISLAK', location: 'scmss', sublocation: 'Manuscripts' }
  }.freeze

  AUTH_INFO_MAP = {
    penn: { url: 'https://aeon.library.upenn.edu/aeon/aeon.dll', param: '1' },
    external: { url: 'https://aeon.library.upenn.edu/nonshib/aeon.dll', param: '2' }
  }.freeze
  BASE_PARAMS = { AeonForm: 'EADRequest', WebRequestForm: 'DefaultRequest', SubmitButton: 'Submit Request' }.freeze

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
    info = REPOSITORY_ATTRIBUTE_MAP[repository_name]
    raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting" unless info

    info
  end

  # @return [Hash{Symbol->String (frozen)}]
  def auth_info(auth_type)
    info = AUTH_INFO_MAP[auth_type.to_sym]
    raise InvalidRequestError, "Invalid auth type specified: #{auth_type}" unless info

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
    day = @params['retrieval_date(3i)'].to_i
    month = @params['retrieval_date(2i)'].to_i
    year = @params['retrieval_date(1i)'].to_i
    DateTime.new(year, month, day).strftime('%m/%d/%Y')
  end

  # @return [Hash{String (frozen)->String (frozen)}]
  def auth_param
    { 'auth' => auth_info(@params[:auth_type])[:param] }
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
    { url: auth_info(@params[:auth_type])[:url],
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
      { 'CallNumber' => @request.call_number, 'ItemTitle' => @request.title, 'ItemAuthor' => '',
        'Site' => @request.repository[:site], 'SubLocation' => @request.repository[:sublocation],
        'Location' => @request.repository[:location], 'ItemVolume' => @container[:volume],
        'ItemIssue' => @container[:issue], 'Request' => @number }
        .transform_keys { |key| key + "_#{@number}" }
    end
  end
end
