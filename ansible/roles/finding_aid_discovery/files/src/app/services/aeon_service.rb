# frozen_string_literal: true

# handle submission of requests to Aeon
class AeonService

  BASE_PARAMS = {
    AeonForm: 'EADRequest', WebRequestForm: 'DefaultRequest', SubmitButton: 'Submit Request'
  }

  # @param [AeonRequest] request
  def self.submit(request)
    @request = request
  end

  class Response
    def initialize(response_body)
      @txnumber = txnumber_from(response_body)
    end

    private

    def txnumber_from(body)
      # TODO regex/noko parse
      # Success: <div id="status"><span class="statusNormal">Transaction(s) 84880 received.</span></div>
    end
  end
end
