# frozen_string_literal: true

# Actions for showing Status information about endpoints
class StatusController < ApplicationController
  layout 'application'

  def index
    @endpoints = Endpoint.all.order(updated_at: :desc)
  end

  def show
    @endpoint = Endpoint.find_by('slug ILIKE ?', params[:id]) # case insensitive
  end
end
