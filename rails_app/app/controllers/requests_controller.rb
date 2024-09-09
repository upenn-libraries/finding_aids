# frozen_string_literal: true

# Actions for handling Aeon requests
class RequestsController < ApplicationController
  before_action :require_container, only: :create

  # show 'confirmation' form with note and date fields
  def create; end

  # return request destination URL and Aeon request body in JSON
  def prepare
    req = AeonRequest.new(params).prepared
    render json: req
  end

  private

  def require_container
    return if params[:c].present?

    redirect_back(fallback_location: root_path,
                  alert: I18n.t('requests.form.messages.missing_container'))
  end
end
