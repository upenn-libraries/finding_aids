# frozen_string_literal: true

# custom Omniauth callbacks
class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[developer saml failure]

  def developer
    request.env['omniauth.auth']
    redirect_to root_path
    # store user_info
    # redirect to proper location
  end

  def saml; end

  def failure
    flash.alert = 'Problem with authentication, try again.'
    redirect_to root_path
  end
end
