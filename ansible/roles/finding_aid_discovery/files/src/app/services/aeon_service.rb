# frozen_string_literal: true

# handle submission of requests to Aeon
class AeonService
  BASE_PARAMS = {
    AeonForm: 'EADRequest', WebRequestForm: 'DefaultRequest', SubmitButton: 'Submit Request'
  }

  # @param [AeonRequest] request
  # @param [Symbol] auth_type- either :penn or :external
  def self.submit(request:, auth_type:)
    http_conn = Faraday.new(url: submit_url(auth_type))
    response = http_conn.post('post', request.to_param) # TODO: add base and auth params?
    if response.status == 200
      Response.new response.body
    else
      # TODO: boom!
    end
  end

  # @param [Symbol] auth_type
  # @return [String (frozen)]
  def self.submit_url(auth_type)
    if auth_type == :penn
      'https://aeon.library.upenn.edu/aeon/aeon.dll'
    elsif auth_type == :external
      'https://aeon.library.upenn.edu/nonshib/aeon.dll'
    else
      # TODO: raise?
    end
  end

  class Response
    attr_reader :txnumber

    def initialize(response_body)
      @txnumber = txnumber_from(response_body)
    end

    # @return [TrueClass, FalseClass]
    def success?
      @txnumber.present?
    end

    private

    # @param [String] body of Aeon web service response
#   # Success: <div id="status"><span class="statusNormal">Transaction(s) 84880 received.</span></div>
    # @return [String] txnumber from Aeon
    def txnumber_from(body)
      doc = Nokogiri::HTML.parse body
      doc.remove_namespaces!
      status_message = body.at_css('#status') # TODO: complete
      status_message.tr('Transaction(s) ', '').tr(' received.', '') # TODO: use a regex to select digits
    end
  end
end
