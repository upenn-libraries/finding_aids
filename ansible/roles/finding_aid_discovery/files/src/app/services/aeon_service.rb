# frozen_string_literal: true

require 'faraday'
require 'faraday/net_http'

# handle submission of requests to Aeon
class AeonService
  class AeonRequestFailedError < StandardError; end

  PENN_AUTH_URL = 'https://aeon.library.upenn.edu/aeon/aeon.dll'
  EXT_AUTH_URL = 'https://aeon.library.upenn.edu/nonshib/aeon.dll'

  # @param [AeonRequest] request
  # @param [Symbol] auth_type- either :penn or :external
  def self.submit(request:, auth_type:)
    http_conn = Faraday.new(url: submit_url(auth_type))
    response = http_conn.post('', request.to_h) # TODO: add auth param based on auth type?
    unless response.status == 200
      raise(AeonRequestFailedError,
            "Aeon submission failed! Request body: #{request.to_param}. Response: #{response.body}")
    end

    Response.new response.body
  end

  # @param [Symbol] auth_type
  # @return [String (frozen)]
  def self.submit_url(auth_type)
    case auth_type.to_sym
    when :penn
      PENN_AUTH_URL
    when :external
      EXT_AUTH_URL
    else
      raise AeonRequestFailedError, "Invalid auth type sent: #{auth_type}"
    end
  end

  # Response object for AeonService
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
    # Success: <div id="status"><span class="statusNormal">Transaction(s) 84880 received.</span></div>
    # @return [String] txnumber from Aeon
    def txnumber_from(body)
      doc = Nokogiri::HTML.parse body
      doc.remove_namespaces!
      status_message = doc.at_css('#status').text
      status_message.tr('Transaction(s) ', '').tr(' received.', '') # TODO: use a regex to select digits
    end
  end
end
