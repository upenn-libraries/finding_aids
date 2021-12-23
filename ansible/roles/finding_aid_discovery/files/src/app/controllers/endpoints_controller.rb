# Actions for showing status information about Endpoints
class EndpointsController < ApplicationController
  layout 'application'
  def index
    @endpoints = Endpoint.all.order(updated_at: :desc)
  end

  def show
    @endpoint = Endpoint.find_by('slug ILIKE ?', params[:id]) # case insensitive
  end
end
