# frozen_string_literal: true

# Actions for handling Aeon requests
class RequestsController < ApplicationController
  # Return request destination URL and Aeon request body in JSON.
  # Called by the modal workflow (issue #312) via the request Stimulus controller.
  # Expects params: repository, title, call_num, request_type, special_request,
  #                  notes, retrieval_date, save_for_later, item[], item_barcode[]
  def prepare
    req = AeonRequest.new(params).prepared
    render json: req
  rescue AeonRequest::InvalidRequestError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
