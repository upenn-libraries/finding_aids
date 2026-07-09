# frozen_string_literal: true

# controller actions for Admin landing page
class AdminController < ApplicationController
  before_action :authenticate_user!

  layout 'application'

  def index; end
end
