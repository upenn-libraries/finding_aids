# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Set cache headers for all controllers
  before_action -> { expires_in 12.hours, public: true }

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout
end
