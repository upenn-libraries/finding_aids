# frozen_string_literal: true

module EndpointsHelper
  # @param [NilClass, String] date
  # @return [String]
  def time_since_last_harvest(date)
    return 'Not harvested yet' if date.blank?

    "#{time_ago_in_words DateTime.parse(date), include_seconds: true} ago"
  end

  # @param [Endpoint] endpoint
  # @param [Hash] file
  # @return [String]
  def error_message_for(endpoint, file)
    if endpoint.penn_aspace_type?
      aspace_link = link_to_penn_aspace_record(
        endpoint.harvest_config['repository_id'], file['id']
      )
      "#{aspace_link}: #{file['errors'].join(', ')}"
    else
      "#{file['id']}: #{file['errors'].join(', ')}"
    end
  end

  # return a URL to a record in ASpace based on environment
  # see: https://gitlab.library.upenn.edu/pacscl/finding-aid-discovery/-/issues/93
  def link_to_penn_aspace_record(endpoint_aspace_id, record_id)
    return '' if record_id.blank? || endpoint_aspace_id.blank?

    base_url = PennArchivesSpaceExtractor::WEB_URL_PRODUCTION
    link_to(record_id,
            "#{base_url}/resolve/edit?uri=/repositories/#{endpoint_aspace_id}/resources/#{record_id}",
            target: '_blank', rel: 'noopener')
  end
end
