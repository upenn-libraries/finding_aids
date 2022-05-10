# frozen_string_literal: true

class AeonRequest
  def initialize(params)
    @items = build_items_from params
  end

  def build_items_from(params)
    # TODO ??? form in #new doesn't yet define expected params
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
    # @param [Hash] data
    # @param [String] number
    def initialize(number, data)
      @number = number
      @data = data
    end

    def to_param
      hash = { 'CallNumber' => '',
               'ItemTitle' => '',
               'ItemAuthor' => '',
               'Site' => '',
               'SubLocation' => '',
               'Location' => '',
               'ItemVolume' => '',
               'ItemIssue' => ''
             }.transform_keys { |key| key += "_#{@number}" }
      hash.store('Request', @number)
      hash
    end
  end
end
