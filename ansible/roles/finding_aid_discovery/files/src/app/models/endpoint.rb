# Represent a partner's endpoint from which we will harvest records
class Endpoint < ApplicationRecord
  TYPES = %w[index]

  validates :slug, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: TYPES
  validates :url, presence: true

  # maybe?
  scope :index_type, -> { where('harvest_config @> ?', { type: 'index' }.to_json) }

  # @return [String]
  def url
    harvest_config['url']
  end

  # @return [String]
  def type
    harvest_config['type']
  end

  # @return [Array]
  def last_harvest_date
    last_harvest_results['date']
  end

  # Return errors that occurred when attempting to load and parse the Endpoint's URL
  # @return [Array]
  def last_harvest_errors
    last_harvest_results['errors']
  end

  # Return file information for those files referenced, downloaded and parsed from the Endpoint's URL
  # @return [Array]
  def last_harvest_files
    last_harvest_results['files']
  end

  # Return Array of file info for files unable to be harvested
  # @return [Array]
  def last_harvest_problem_files
    @last_harvest_problem_files ||= Array.wrap(
      last_harvest_files&.select do |file|
        file['status'] == 'failed'
      end
    )
  end

  # Return Array of file info for files able to be harvested
  # @return [Array]
  def last_harvest_success_files
    @last_harvest_success_files ||= Array.wrap(
      last_harvest_files&.select do |file|
        file['status'] == 'ok'
      end
    )
  end

  # Return boolean for the success of the last harvest - success being defined
  # by the absence of any errors in parsing the endpoint URL
  # @return [TrueClass, FalseClass]
  def last_harvest_successful?
    last_harvest_errors&.empty?
  end

  # Did the last harvest run into any issues parsing any individual files?
  # @return [TrueClass, FalseClass]
  def last_harvest_warnings?
    last_harvest_problem_files.any?
  end

  # Did the last harvest fail? If so, an error will be present in the top-level of the results hash
  # @return [TrueClass, FalseClass]
  def last_harvest_failed?
    last_harvest_errors&.any?
  end

  # @return [Object]
  def extractor
    @extractor ||= extractor_class.new(self)
  end

  # Return Class for extracting XML File URLs from a source
  def extractor_class
    "#{type.titlecase}Extractor".constantize
  end

  # @return [Object]
  def parser
    @parser ||= parser_class.new(self)
  end

  # Return Class for parsing xml_urls for this Endpoint, using
  # 'parser' value in harvest_config, if present
  def parser_class
    if harvest_config.dig('parser', nil).present?
      "#{harvest_config['parser']}Parser".constantize
    else
      EadParser
    end
  end
end
