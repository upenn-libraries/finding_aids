# frozen_string_literal: true

class AeonRequest
  attr_reader :items

  def initialize(params)
    @items = build_items_from params
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
               'Site' => '', # internally mapped? see JS
               'SubLocation' => '', # internally mapped? see JS
               'Location' => '', # from repository value? see JS
               'ItemVolume' => @container.try(:type),
               'ItemIssue' => @container.try(:text)
             }.transform_keys { |key| key += "_#{@number}" }
      hash.store('Request', @number)
      hash
    end
  end
end
