# frozen_string_literal: true

# Actions for showing status information about Endpoints
class RequestsController < ApplicationController
  # show 'confirmation' form with note and date fields
  # TODO: raise if no c[] params? we dont want empty requests...
  def new; end

  # return request destination URL and Aeon request body in JSON
  def prepare
    render json: AeonRequest.new(params).prepared
  end
end
