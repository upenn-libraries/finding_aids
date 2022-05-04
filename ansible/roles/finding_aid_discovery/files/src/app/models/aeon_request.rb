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

  def submit
    # map params
    #
    # build POST body
    #
    # send POST - URL can depend on auth type

    return Response.new(response_body)
  end

  def base_params
    {   auth: 1,
        UserReview: 'Yes', # TODO: this is set if a retrieval date is not selected?
        AeonForm: 'EADRequest',
        WebRequestForm: 'DefaultRequest',
        SubmitButton: 'Submit Request',
    }
  end

  class Response
    def initialize(response_body)
      @txnumber = txnumber_from(response_body)
    end

    private

    def txnumber_from(body)
      # TODO regex/noko parse
      # <div id="status"><span class="statusNormal">Transaction(s) 84880 received.</span></div>
    end
  end

  class Item
    def initialize(number, data)
      @number = number
      @data = data
    end

    def to_param
      {
        CallNumber: '',
        ItemTitle: '',
        ItemAuthor: '',
        Site: '',
        SubLocation: '',
        Location: '',
        ItemVolume: '',
        ItemIssue: ''
      }.transform_keys do |key|
        key.to_s += "_#{@number}"
      end
    end
  end
end
