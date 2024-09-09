# frozen_string_literal: true

# Controller for authenticated routes
class AdminController < ApplicationController
  before_action :authenticate_user!
  def index; end
end
