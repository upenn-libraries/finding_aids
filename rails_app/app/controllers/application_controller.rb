# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  # Path to redirect users to after successful authentication
  def after_sign_in_path_for(_resource)
    admin_path
  end

  # @param [Symbol] action controller action
  # @param [String] class_name class name of the object
  # @param [String] identifier attribute identifying the object (e.g slug or email)
  def notify_success(action:, class_name:, identifier:)
    flash.notice = I18n.t("admin.flash.#{action}.success", class_name: class_name, identifier: identifier)
  end

  # @param [Symbol] action controller action
  # @param [String] class_name class name of the object
  # @param [String] identifier attribute identifying the object (e.g slug or email)
  # @param [String] error error message
  def alert_failure(action:, class_name:, identifier:, error:)
    flash.alert = I18n.t("admin.flash.#{action}.failure", class_name: class_name, identifier: identifier, error: error)
  end
end
