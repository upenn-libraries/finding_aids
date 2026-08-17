# frozen_string_literal: true

module Aeon
  # TODO: functionality remaining here is to be ported to JS
  class Request
    # @return [Hash{String (frozen)->String}]
    def note_fields
      { SpecialRequest: params[:special_request].to_s,
        Notes: params[:notes].to_s }
    end

    def return_link_fields
      { ReturnLinkUrl: params[:return_url].to_s,
        ReturnLinkSystemName: Settings.aeon.system_name }
    end

    # @return [String]
    def call_number
      params[:call_num] || 'n/a'
    end

    private

    # @return [String]
    def formatted_retrieval_date
      Date.parse(params['retrieval_date']).strftime('%m/%d/%Y')
    rescue StandardError => e
      Honeybadger.notify("Problem parsing retrieval date: #{e.message}")
      nil
    end
  end
end
