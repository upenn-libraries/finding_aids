module EndpointsHelper
  # @param [NilClass, String] date
  # @return [String]
  def time_since_last_harvest(date)
    return 'Not harvested yet' unless date.present?

    "#{time_ago_in_words DateTime.parse(date), include_seconds: true} ago"
  end
end
