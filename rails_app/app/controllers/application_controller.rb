# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  # Path to redirect users to after successful authentication
  def after_sign_in_path_for(_resource)
    admin_path
  end
end
