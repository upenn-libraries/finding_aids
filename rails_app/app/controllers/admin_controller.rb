# frozen_string_literal: true

# controller actions for Admin landing page
class AdminController < ApplicationController
  before_action :authenticate_user!

  layout 'application'

  def index; end

  def refresh_map_data
    HomepageData.reset!
    notify_success action: :refresh, class_name: 'Map data', identifier: 'cache'
    redirect_to endpoints_path
  end
end
