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

  attr_reader :items, :repository

  # @param [ActionController::Parameters] params
  def initialize(params)
    @items = build_items_from params
    @repository = repository_info params[:repository].to_s
    @params = params
  end

  def build_items_from(params)
    params['item'].map.with_index do |item, i|
      volume, issue = item.split(':').map(&:strip)
      container_info = { volume: volume, issue: issue }
      Item.new i, container_info, self
    end
  end

  # @return [Proc]
  # @param [String] repository_name
  def repository_info(repository_name)
    repository_hash = case repository_name
                      when KISLAK_REPOSITORY_NAME
                        KISLAK_REPOSITORY_ATTRIBUTES
                      when KATZ_REPOSITORY_NAME
                        KATZ_REPOSITORY_ATTRIBUTES
                      else
                        raise InvalidRequestError, "Repository #{repository_name} does not support Aeon requesting"
                      end
    repository_hash.to_proc
  end

  # @return [Hash{String (frozen)->String}]
  def note_fields
    { 'SpecialRequest' => @params[:special_request].to_s,
      'Notes' => @params[:notes].to_s }
  end

  def fulfillment_fields
    { 'UserReview' => @params[:save_for_later] ? 'Yes' : 'No', # TODO: confirm booleanness of param after paramification
      'ScheduledDate' => @params[:retrieval_date] } # TODO: ensure format - m/d/yyyy
  end

  # @return [Hash]
  def to_param
    BASE_PARAMS + note_fields + fulfillment_fields + @items.map(&:to_param).flatten
  end

  # Typical Aeon params:
  #
  # SpecialRequest=notes & questions
  # Notes=my notes
  # auth=1
  # UserReview=Yes
  # AeonForm=EADRequest
  # WebRequestForm=DefaultRequest
  # SubmitButton=Submit Request
  # Request=0
  # ItemTitle_0=
  # CallNumber_0=Ms. Coll. 1375
  # Site_0=KISLAK
  # SubLocation_0=Manuscripts
  # Location_0=scmss
  # ItemVolume_0=Box 1
  # ItemIssue_0=Album 1, 2

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

    def to_param
      hash = { 'CallNumber' => @request.call_number,
               'ItemTitle' => @request.title,
               'ItemAuthor' => '', # ever set?
               'Site' => @repository.site,
               'SubLocation' => @repository.sublocation,
               'Location' => @repository.location,
               'ItemVolume' => @container.try(:volume),
               'ItemIssue' => @container.try(:issue) }
             .transform_keys { |key| key + "_#{@number}" }
      hash.store('Request', @number)
      hash
    end
  end
end
