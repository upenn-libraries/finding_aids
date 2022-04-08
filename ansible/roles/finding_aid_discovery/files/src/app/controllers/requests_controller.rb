# frozen_string_literal: true

# Actions for showing status information about Endpoints
class RequestsController < ApplicationController
  # show 'confirmation' form with note and date fields
  def new; end

  # validate and map params then ship to Aeon endpoint
  def create; end

  # show request response from Aeon, etc.
  def show; end
end
