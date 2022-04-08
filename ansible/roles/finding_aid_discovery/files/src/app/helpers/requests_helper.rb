# frozen_string_literal: true

# helpers for
module RequestsHelper
  # @param [ActionController::Parameters] params
  # @return [Array<String>]
  def containers_from_params(params)
    params[:c].keys.map do |container|
      container.gsub(/req_\d/, '').tr('_', ' ').titleize
    end
  end
end
