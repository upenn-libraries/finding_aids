# frozen_string_literal: true

# Actions for showing status information about Endpoints
class RequestsController < ApplicationController
  # show 'confirmation' form with note and date fields
  def new; end

  # validate and map params then ship to Aeon endpoint
  def create
    aeon_request = AeonRequest.new request_params
    response = aeon_request.submit
    if response.txnumber
      redirect_to request_path
    else
      flash[:alert] = "Failed to create Aeon request"
      render :new
    end
  end

  # show request response from Aeon, etc.
  def show; end
end
