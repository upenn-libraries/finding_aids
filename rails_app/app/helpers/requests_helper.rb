# frozen_string_literal: true

# helpers for Aeon requesting
module RequestsHelper
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
