# frozen_string_literal: true

# helpers for Aeon requesting
module RequestsHelper
  # Turn form params into a nice hash, aggregating page/issue requests per volume
  # @param [ActionController::Parameters] params
  # @return [Array]
  def containers_from_params(params)
    return [] if params[:c].blank?

    params[:c].to_unsafe_h.map do |k, v|
      parts = k.split('_')
      barcode = parts.count == 3 ? parts[2] : nil
      volume = parts[0..1].join(' ')
      # if v is 1 that is the input value and indicates the presence of only 1 container
      value = v == '1' ? volume : "#{volume}: #{issues_from_param(v)}"
      { value: value, barcode: barcode }
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

  # @return [String (frozen)]
  def penn_aeon_auth_url
    AeonRequest::AUTH_INFO_MAP[:penn][:url]
  end

  # Per-request-type copy + dynamic text the Stimulus controller swaps/inserts
  # at runtime. Serialized to a JSON value on the controller element.
  # @return [Hash]
  def request_copy_value
    {
      visit: t('show.sections.request.visit'),
      copy: t('show.sections.request.copy'),
      step_review: t('show.sections.request.step_review'),
      step_auth: t('show.sections.request.step_auth'),
      bar_count_one: t('show.sections.request.bar.count_one'),
      bar_count_many: t('show.sections.request.bar.count_many'),
      remove: t('show.sections.request.remove'),
      remove_aria: t('show.sections.request.remove_aria'),
      section_count: t('show.sections.request.section_count'),
      announce_added: t('show.sections.request.announce_added'),
      announce_removed: t('show.sections.request.announce_removed'),
      no_container: t('show.sections.request.no_container')
    }
  end

  # @param document [SolrDocument]
  # @return [String] per-collection localStorage key for request selections
  def request_storage_key(document)
    "fa-visit:#{document.id}"
  end
end
