# frozen_string_literal: true

# helpers for
module RequestsHelper
  # @param [ActionController::Parameters] params
  # @return [Array<String>]
  def containers_from_params(params)
    params[:c].keys.map do |container|
      containers_info = container.gsub(/req_\d_/, '').split('\\')
      containers_info.map { |c| c.tr('|', ' ') }.join(', ').titleize
    end
  end
end
