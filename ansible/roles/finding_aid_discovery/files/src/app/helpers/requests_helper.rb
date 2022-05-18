# frozen_string_literal: true

# helpers for Aeon requesting
module RequestsHelper
  # Turn form params into a nice hash, aggregating page/issue requests per volume
  # @param [ActionController::Parameters] params
  # @return [Array<String>]
  def containers_from_params(params)
    params[:c].to_unsafe_h.map do |k, v|
      volume = k.tr('_', ' ')
      "#{volume}: #{issues_from_param(v)}"
    end
  end

  # Turn a hash of requests from a volume into a human-friendly string
  # @param [Hash] param
  # @return [String (frozen)]
  def issues_from_param(param)
    first_issue = param.keys.first
    return unless first_issue

    label = first_issue.split('_').first
    issues = param.keys.map { |k| k.split('_').second }.join(', ')
    "#{label} #{issues}"
  end
end
