class EndpointsController < ApplicationController
  layout 'application'
  def index
    @endpoints = Endpoint.all.order(updated_at: :desc)
  end
end
