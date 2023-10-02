# frozen_string_literal: true

# handles requests from user login entrypoint
class LoginController < ApplicationController
  def index
    if Rails.env.development?
       render :index
    else
      head :not_found
    end
  end
end
