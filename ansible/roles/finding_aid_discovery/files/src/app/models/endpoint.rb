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

  # @return [Array]
  def last_harvest_errors
    last_harvest_results['errors']
  end

  def last_harvest_files
    last_harvest_results['files']
  end

  def last_harvest_error_files
    @last_harvest_error_files ||= last_harvest_files.select do |file|
      file['status'] == 'failed'
    end
  end

  # @return [TrueClass, FalseClass]
  def last_harvest_successful?
    last_harvest_errors&.empty?
  end

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
