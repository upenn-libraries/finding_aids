# frozen_string_literal: true

module EndpointsHelper
  # @param [NilClass, String] date
  # @return [String]
  def time_since_last_harvest(date)
    return 'Not harvested yet' if date.blank?

    "#{time_ago_in_words DateTime.parse(date), include_seconds: true} ago"
  end

  # @param [Hash] file
  # @return [String]
  def error_message_for(file)
    "#{file['id']}: #{file['errors'].join(', ')}"
  end

  # Class of the table row depending on harvest status
  # @param [Endpoint::LastHarvest] last_harvest
  # @return [String]
  def table_row_class(last_harvest)
    if last_harvest.failed?
      'table-danger'
    elsif last_harvest.inactive?
      'table-warning'
    else
      ''
    end
  end
end
