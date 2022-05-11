# frozen_string_literal: true

# Represent a request of one or more items to Aeon
class AeonRequest
  KISLAK_REPOSITORY_NAME =
    'University of Pennsylvania: Kislak Center for Special Collections, Rare Books and Manuscripts'
  KISLAK_REPOSITORY_ATTRIBUTES = { site: 'KISLAK', location: 'scmss', sublocation: 'Manuscripts' }.freeze

  KATZ_REPOSITORY_NAME =
    'University of Pennsylvania: Archives at the Library of the Katz Center for Advanced Judaic Studies'
  KATZ_REPOSITORY_ATTRIBUTES = { site: 'KATZ', location: 'cjsarcms', sublocation: 'Arc Room Ms.' }.freeze

  attr_reader :items, :repository

  def initialize(params)
    @items = build_items_from params
    @repository = repository_info params[:repository]
    # TODO: notes fields?
  end

  def build_items_from(params)
    item_params = params.select { |k, _v| k.starts_with? 'item' }.values
    item_params.map.with_index do |item, i|
      containers = item.split(',')
      container_info = {}
      container_info[:type] = containers[0] if containers[0].present?
      container_info[:text] = containers[1] if containers[1].present?
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
                        # TODO: raise?
                      end
    repository_hash.to_proc
  end

  # TODO: aggregate base params, item params 'n stuff
  def to_param
    @items.map(&:to_param).flatten
  end

  # Submit request to Aeon
  #
  # e.g.,
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
               'ItemVolume' => @container.try(:type),
               'ItemIssue' => @container.try(:text) }
               .transform_keys { |key| key + "_#{@number}" }
      hash.store('Request', @number)
      hash
    end
  end
end
