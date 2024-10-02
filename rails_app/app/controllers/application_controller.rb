# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  # Path to redirect users to after successful authentication
  # @todo use endpoints_path when that is available
  def after_sign_in_path_for(_resource)
    users_path
  end
end
