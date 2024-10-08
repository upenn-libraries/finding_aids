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
    if endpoint.aspace_type?
      aspace_link = link_to_aspace_record(
        endpoint, file['id']
      )
      "#{aspace_link}: #{file['errors'].join(', ')}"
    else
      "#{file['id']}: #{file['errors'].join(', ')}"
    end
  end

  # return a URL to a record in ASpace based on environment
  # see: https://gitlab.library.upenn.edu/dld/finding-aids/-/issues/93
  def link_to_aspace_record(endpoint, record_id)
    return '' if record_id.blank? || endpoint.aspace_repo_id.blank? || endpoint.aspace_instance.blank?

    base_url = endpoint.aspace_instance.base_url
    link_to(record_id, "#{base_url}/resolve/edit?uri=/repositories/#{endpoint.aspace_repo_id}/resources/#{record_id}",
            target: '_blank', rel: 'noopener')
  end
end
