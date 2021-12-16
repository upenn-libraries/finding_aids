class EndpointsController < ApplicationController
  layout 'application'
  def index
    @endpoints = Endpoint.all
  end
end
